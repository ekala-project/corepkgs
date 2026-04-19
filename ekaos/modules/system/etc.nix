# /etc file management
# Builds the /etc directory for the system
{ config, lib, pkgs, ... }:

with lib;

let
  etc' = filter (f: f.enable) (attrValues config.environment.etc);

  # Build the /etc directory
  etcDir = pkgs.runCommand "etc" {
    preferLocalBuild = true;
  } ''
    mkdir -p $out/etc

    ${concatMapStringsSep "\n" (file: ''
      mkdir -p $out/etc/$(dirname ${escapeShellArg file.target})
      ${if file.source != null then ''
        ln -s ${file.source} $out/etc/${escapeShellArg file.target}
      '' else ''
        cat > $out/etc/${escapeShellArg file.target} <<'EOF'
        ${file.text}
        EOF
        ${optionalString (file.mode != null) "chmod ${file.mode} $out/etc/${escapeShellArg file.target}"}
      ''}
    '') etc'}
  '';

in

{
  options = {
    environment.etc = mkOption {
      type = types.attrsOf (types.submodule ({ name, config, ... }: {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this /etc file should be generated.";
          };

          target = mkOption {
            type = types.str;
            default = name;
            description = "Name of the file in /etc (relative path).";
          };

          text = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = "Text content of the file.";
          };

          source = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Source file to symlink.";
          };

          mode = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "0600";
            description = "File mode (permissions).";
          };
        };

        config = {
          # Ensure either text or source is set
          source = mkIf (config.text != null) (
            mkDefault (pkgs.writeText name config.text)
          );
        };
      }));
      default = {};
      description = ''
        Files to include in /etc.

        Each attribute defines a file in /etc with its content or source.
      '';
      example = literalExpression ''
        {
          "hostname".text = "myhost";
          "hosts".text = '''
            127.0.0.1 localhost
            ::1 localhost
          ''';
        }
      '';
    };

    system.build.etc = mkOption {
      type = types.package;
      internal = true;
      description = "The /etc directory for the system.";
    };
  };

  config = {
    system.build.etc = etcDir;

    # Essential /etc files for a bootable system
    environment.etc = {
      "fstab".text = ''
        # Static file system configuration
        # Managed by ekaos

        # Special filesystems
        proc /proc proc defaults 0 0
        sysfs /sys sysfs defaults 0 0
        devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
        devpts /dev/pts devpts mode=0620,gid=3,nosuid,noexec 0 0
        tmpfs /run tmpfs mode=0755,nosuid,nodev,size=25% 0 0
        tmpfs /dev/shm tmpfs mode=1777,nosuid,nodev 0 0
      '';

      "os-release".text = ''
        NAME="ekaos"
        ID=ekaos
        VERSION="${config.system.ekaos.version}"
        VERSION_ID="${config.system.ekaos.version}"
        PRETTY_NAME="ekaos ${config.system.ekaos.version}"
        HOME_URL="https://github.com/your-org/ekaos"
      '';

      "issue".text = ''
        ekaos ${config.system.ekaos.version} \n \l

      '';
    };
  };
}
