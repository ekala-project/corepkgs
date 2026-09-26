# Adios port of ekaos/modules/security/wrappers/default.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# NOTE: the `./wrapper.nix` package builder is referenced relatively exactly
# as in the legacy module; that file is copied verbatim (NON-MODULE).
{ types, pkgs, ... }:
let
  # Local reimplementation of nixpkgs `lib.filterAttrs` (see conversion table).
  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );

  # File mode type from the legacy module (taken from the chmod(1) man page).
  # TODO(adios-cutover): legacy `strMatching` enum validation becomes a
  # single adios assertion over all wrappers below.
  modePattern =
    let
      symbolic = "[ugoa]*([-+=]([rwxXst]*|[ugo]))+|[-+=][0-7]+";
      numeric = "[-+=]?[0-7]{0,4}";
    in
    "((${symbolic})(,${symbolic})*)|(${numeric})";
in
{
  options = {
    enableWrappers = {
      type = types.bool;
      default = true;
      description = "Whether to enable SUID/SGID wrappers.";
    };

    wrappers = {
      # TODO(adios-cutover): submodule validation lost (legacy `wrapperType`
      # submodule with enable/source/program/owner/group/permissions/
      # capabilities/setuid/setgid, including `config.program = mkDefault name`).
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        # a setuid root program
        sudo = {
          setuid = true;
          owner = "root";
          group = "root";
          source = "\${pkgs.sudo}/bin/sudo";
        };

        # a program with capabilities
        ping = {
          owner = "root";
          group = "root";
          capabilities = "cap_net_raw+ep";
          source = "\${pkgs.iputils.out}/bin/ping";
        };
      };
      description = ''
        This option effectively allows adding setuid/setgid bits, capabilities,
        changing file ownership and permissions of a program without directly
        modifying it. This works by creating a wrapper program in a directory
        which is then added to the shell PATH.
      '';
    };

    wrapperDir = {
      # NOTE: korora types.path only accepts Nix path literals, while legacy
      # types.path also accepts strings. pathLike covers both.
      type = types.pathLike;
      default = "/run/wrappers/bin";
      # TODO(adios-cutover): legacy option is internal (should not be overridden).
      description = ''
        This option defines the path to the wrapper programs. It
        should not be overridden.
      '';
    };
  };

  inputs = {
    users.from = { root }: root.config."users-groups";
    # TODO(adios-cutover): `inputs.users.users`/`inputs.users.groups` assumes
    # a parent.users tree node exposes users/groups maps; verify against the
    # users/groups port (unresolvable from this batch).
  };

  assertions = [
    {
      verify =
        { options }:
        builtins.all (w: builtins.match modePattern (w.permissions or "u+rx,g+x,o+x") != null) (
          builtins.attrValues options.wrappers
        );
      explain = { options }: "security.wrappers permissions must be a valid file mode string";
    }
  ];

  impl =
    { options, inputs }:
    let
      wrapperDir = options.wrapperDir;

      wrappers = filterAttrs (name: value: value.enable or true) options.wrappers;

      parentWrapperDir = builtins.dirOf wrapperDir;

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
        else if inputs.users.users ? ${user} && inputs.users.users.${user}.uid != null then
          toString inputs.users.users.${user}.uid
        else
          user;

      resolveGid =
        group:
        if group == "root" then
          "0"
        else if inputs.users.groups ? ${group} && inputs.users.groups.${group}.gid != null then
          toString inputs.users.groups.${group}.gid
        else
          group;

      # TODO(adios-cutover): legacy `config.program = mkDefault name` (wrapper
      # program defaults to its attribute name) is replicated here by mapping
      # over attrNames instead of attrValues.
      mkWrappedPrograms = builtins.map (
        name:
        let
          opts = wrappers.${name};
          optsWithIds = opts // {
            owner = resolveUid (opts.owner or "root");
            group = resolveGid (opts.group or "root");
          };
          withDefaults = optsWithIds // {
            program = optsWithIds.program or name;
            capabilities = optsWithIds.capabilities or "";
            setuid = optsWithIds.setuid or false;
            setgid = optsWithIds.setgid or false;
            permissions = optsWithIds.permissions or "u+rx,g+x,o+x";
          };
        in
        if withDefaults.capabilities != "" then
          mkSetcapProgram withDefaults
        else
          mkSetuidProgram withDefaults
      ) (builtins.attrNames wrappers);
    in
    if options.enableWrappers then
      {
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

            ${builtins.concatStringsSep "\n" mkWrappedPrograms}

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
      }
    else
      { };
}
