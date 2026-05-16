# Security wrappers for SUID/SGID/capabilities programs
# Provides safe handling of privileged executables
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.security) wrapperDir;

  wrappers = lib.filterAttrs (name: value: value.enable) config.security.wrappers;

  parentWrapperDir = dirOf wrapperDir;

  # Build the security wrapper
  securityWrapper =
    sourceProg:
    pkgs.callPackage ./wrapper.nix {
      inherit sourceProg;

      # Extract unsecvars.h from glibc source for environment variable filtering
      unsecvars =
        pkgs.runCommand "glibc-unsecvars"
          {
            src =
              pkgs.glibc.src or (builtins.fetchTarball {
                url = "https://ftp.gnu.org/gnu/glibc/glibc-2.40.tar.xz";
                sha256 = "0jv1n66jlvf6xvc0bxhz7pxk3s9dqsf3xnkxx4p4xj4gna8jx2mg";
              });
          }
          ''
            mkdir $out
            tar -xf $src --strip-components=1 -C . glibc-*/sysdeps/generic/unsecvars.h 2>/dev/null || \
            tar -xf $src --wildcards -C . '*/sysdeps/generic/unsecvars.h' --strip-components=3 || \
            echo '/* Fallback: empty unsecvars */\n#define UNSECURE_ENVVARS ""' > unsecvars.h
            cp unsecvars.h $out/ || cp ./sysdeps/generic/unsecvars.h $out/
          '';
    };

  fileModeType =
    let
      # taken from the chmod(1) man page
      symbolic = "[ugoa]*([-+=]([rwxXst]*|[ugo]))+|[-+=][0-7]+";
      numeric = "[-+=]?[0-7]{0,4}";
      mode = "((${symbolic})(,${symbolic})*)|(${numeric})";
    in
    lib.types.strMatching mode // { description = "file mode string"; };

  wrapperType = lib.types.submodule (
    { name, config, ... }:
    {
      options.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the wrapper.";
      };
      options.source = lib.mkOption {
        type = lib.types.path;
        description = "The absolute path to the program to be wrapped.";
      };
      options.program = lib.mkOption {
        type = with lib.types; nullOr str;
        default = name;
        description = ''
          The name of the wrapper program. Defaults to the attribute name.
        '';
      };
      options.owner = lib.mkOption {
        type = lib.types.str;
        description = "The owner of the wrapper program.";
      };
      options.group = lib.mkOption {
        type = lib.types.str;
        description = "The group of the wrapper program.";
      };
      options.permissions = lib.mkOption {
        type = fileModeType;
        default = "u+rx,g+x,o+x";
        example = "a+rx";
        description = ''
          The permissions of the wrapper program. The format is that of a
          symbolic or numeric file mode understood by chmod.
        '';
      };
      options.capabilities = lib.mkOption {
        type = lib.types.commas;
        default = "";
        description = ''
          A comma-separated list of capability clauses to be given to the
          wrapper program. The format for capability clauses is described in the
          "TEXTUAL REPRESENTATION" section of the cap_from_text(3) manual page.
        '';
      };
      options.setuid = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to add the setuid bit the wrapper program.";
      };
      options.setgid = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to add the setgid bit the wrapper program.";
      };
    }
  );

  # Activation script for setcap wrappers
  mkSetcapProgram =
    {
      program,
      capabilities,
      source,
      owner,
      group,
      permissions,
      ...
    }:
    ''
      cp ${securityWrapper source}/bin/security-wrapper "$wrapperDir/${program}"

      # Prevent races
      chmod 0000 "$wrapperDir/${program}"
      chown ${owner}:${group} "$wrapperDir/${program}"

      # Set desired capabilities on the file plus cap_setpcap so
      # the wrapper program can elevate the capabilities set on
      # its file into the Ambient set.
      ${pkgs.libcap.out}/bin/setcap "cap_setpcap,${capabilities}" "$wrapperDir/${program}"

      # Set the executable bit
      chmod ${permissions} "$wrapperDir/${program}"
    '';

  # Activation script for setuid wrappers
  mkSetuidProgram =
    {
      program,
      source,
      owner,
      group,
      setuid,
      setgid,
      permissions,
      ...
    }:
    ''
      cp ${securityWrapper source}/bin/security-wrapper "$wrapperDir/${program}"

      # Prevent races
      chmod 0000 "$wrapperDir/${program}"
      chown ${owner}:${group} "$wrapperDir/${program}"

      chmod "u${if setuid then "+" else "-"}s,g${if setgid then "+" else "-"}s,${permissions}" "$wrapperDir/${program}"
    '';

  # Helper to resolve user/group names to numeric IDs
  # This is needed because during disk image build, the user database isn't available
  resolveUid =
    user:
    if user == "root" then
      "0"
    else if config.users.users ? ${user} && config.users.users.${user}.uid != null then
      toString config.users.users.${user}.uid
    else
      user;

  resolveGid =
    group:
    if group == "root" then
      "0"
    else if config.users.groups ? ${group} && config.users.groups.${group}.gid != null then
      toString config.users.groups.${group}.gid
    else
      group;

  mkWrappedPrograms = map (
    opts:
    let
      optsWithIds = opts // {
        owner = resolveUid opts.owner;
        group = resolveGid opts.group;
      };
    in
    if opts.capabilities != "" then mkSetcapProgram optsWithIds else mkSetuidProgram optsWithIds
  ) (lib.attrValues wrappers);
in
{
  options = {
    security.enableWrappers = lib.mkEnableOption "SUID/SGID wrappers" // {
      default = true;
    };

    security.wrappers = lib.mkOption {
      type = lib.types.attrsOf wrapperType;
      default = { };
      example = lib.literalExpression ''
        {
          # a setuid root program
          sudo =
            { setuid = true;
              owner = "root";
              group = "root";
              source = "''${pkgs.sudo}/bin/sudo";
            };

          # a program with capabilities
          ping =
            { owner = "root";
              group = "root";
              capabilities = "cap_net_raw+ep";
              source = "''${pkgs.iputils.out}/bin/ping";
            };
        }
      '';
      description = ''
        This option effectively allows adding setuid/setgid bits, capabilities,
        changing file ownership and permissions of a program without directly
        modifying it. This works by creating a wrapper program in a directory
        which is then added to the shell PATH.
      '';
    };

    security.wrapperDir = lib.mkOption {
      type = lib.types.path;
      default = "/run/wrappers/bin";
      internal = true;
      description = ''
        This option defines the path to the wrapper programs. It
        should not be overridden.
      '';
    };
  };

  config = lib.mkIf config.security.enableWrappers {
    # Add profile script to set PATH
    environment.etc."profile.d/security-wrappers.sh".text = ''
      # Add security wrappers to PATH
      export PATH="${wrapperDir}:$PATH"
    '';

    # Create wrappers during system activation
    system.activationScripts.wrappers = {
      deps = [
        "etc"
        "users"
      ];
      text = ''
        echo "Setting up security wrappers..."

        # Create parent directory as tmpfs mount point
        mkdir -p ${parentWrapperDir}

        # Mount tmpfs if not already mounted
        if ! mountpoint -q ${parentWrapperDir} 2>/dev/null; then
          mount -t tmpfs -o nodev,mode=755,size=50% tmpfs ${parentWrapperDir} || true
        fi

        # Create a new wrapper directory with a unique name
        wrapperDir=$(mktemp -d "${parentWrapperDir}/wrappers.XXXXXXXXXX")
        chmod a+rx "$wrapperDir"

        ${lib.concatStringsSep "\n" mkWrappedPrograms}

        # Atomically replace the symlink
        if [ -L ${wrapperDir} ]; then
          old=$(readlink -f ${wrapperDir})
          ln -sfn "$wrapperDir" "${wrapperDir}.tmp"
          mv -T "${wrapperDir}.tmp" "${wrapperDir}"
          rm -rf "$old"
        else
          # For initial setup
          ln -sfn "$wrapperDir" "${wrapperDir}"
        fi

        echo "Security wrappers installed at ${wrapperDir}"
      '';
      supportsDryActivation = false;
    };
  };
}
