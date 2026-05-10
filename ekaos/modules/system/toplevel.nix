# Top-level system builder
# Creates the system closure derivation
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Generate bootspec (boot.json) for the system
  bootspecJson = pkgs.writeText "bootspec.json" (
    builtins.toJSON (
      {
        "org.nixos.bootspec.v1" = {
          system = pkgs.stdenv.hostPlatform.system;
          kernel = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";
          kernelParams = config.boot.kernelParams;
          init = "@init@"; # Will be substituted
          toplevel = "@toplevel@"; # Will be substituted
          label = config.system.ekaos.label;
          inherit (config.system.ekaos) version;
        }
        // optionalAttrs config.boot.initrd.enable {
          # Include initrd in bootspec when enabled
          initrd = "@initrd@"; # Will be substituted
        };
      }
      // optionalAttrs (config.boot.loader.systemd-boot.enable or false) {
        "org.nixos.systemd-boot" = {
          sortKey = config.boot.loader.systemd-boot.sortKey;
        };
      }
    )
  );

  # Build the system closure
  systemBuilder = ''
    set -e
    mkdir -p $out

    # Copy and configure the init script (stage-2)
    cp ${config.system.build.bootStage2} $out/init
    chmod +x $out/init

    # Substitute system configuration path
    substituteInPlace $out/init \
      --subst-var-by systemConfig $out

    # Copy activation script
    cp ${config.system.build.activationScript} $out/activate
    chmod +x $out/activate

    # Substitute @out@ in activation script
    substituteInPlace $out/activate \
      --replace '@out@' "$out"

    # Create symlinks to key components
    ln -s ${config.system.build.etc}/etc $out/etc
    ln -s ${config.system.path} $out/sw
    ln -s ${config.systemd.package} $out/systemd

    # Write version information
    echo -n "${config.system.ekaos.version}" > $out/ekaos-version
    echo -n "systemd ${toString config.systemd.package.interfaceVersion}" > $out/init-interface-version
    echo -n "${pkgs.stdenv.hostPlatform.system}" > $out/system

    # Copy initrd if enabled
    ${optionalString config.boot.initrd.enable ''
      cp ${config.system.build.initrd}/initrd $out/initrd
    ''}

    # Generate bootspec (boot.json)
    ${
      if config.boot.initrd.enable then
        ''
          ${pkgs.jq}/bin/jq \
            '."org.nixos.bootspec.v1".toplevel = $toplevel |
             ."org.nixos.bootspec.v1".init = $init |
             ."org.nixos.bootspec.v1".initrd = $initrd' \
            --arg toplevel "$out" \
            --arg init "$out/init" \
            --arg initrd "$out/initrd" \
            < ${bootspecJson} > $out/boot.json
        ''
      else
        ''
          ${pkgs.jq}/bin/jq \
            '."org.nixos.bootspec.v1".toplevel = $toplevel |
             ."org.nixos.bootspec.v1".init = $init' \
            --arg toplevel "$out" \
            --arg init "$out/init" \
            < ${bootspecJson} > $out/boot.json
        ''
    }

    # Create extra dependencies file for GC roots
    mkdir -p $out/extra-dependencies
    ln -s ${config.boot.kernelPackages.kernel} $out/extra-dependencies/kernel
    ${optionalString config.boot.initrd.enable ''
      ln -s ${config.system.build.initrd} $out/extra-dependencies/initrd
    ''}
  '';

  # The top-level system derivation
  baseSystem = pkgs.stdenvNoCC.mkDerivation {
    name = "ekaos-system-${config.system.ekaos.label}";
    preferLocalBuild = true;
    allowSubstitutes = false;

    buildCommand = systemBuilder;

    # Pass through for use in scripts
    inherit (pkgs) jq;
    inherit (config.systemd) package;
  };

in

{
  options = {
    system.ekaos.version = mkOption {
      type = types.str;
      default = "24.11";
      description = "The ekaos version string.";
    };

    system.ekaos.label = mkOption {
      type = types.str;
      default = "ekaos";
      description = "Label for the system (shown in boot menu).";
    };

    system.build.toplevel = mkOption {
      type = types.package;
      description = ''
        The complete system closure.

        This derivation contains everything needed to boot and run
        the system: init script, activation script, /etc, packages, etc.
      '';
    };

    system.build.nixos-install = mkOption {
      type = types.package;
      default = pkgs.nixos-install;
      description = "The nixos-install tool for installing the system.";
    };

    system.build.nixos-enter = mkOption {
      type = types.package;
      default = pkgs.nixos-enter;
      description = "The nixos-enter tool for entering a NixOS chroot.";
    };

    system.path = mkOption {
      type = types.package;
      description = ''
        The system environment (/run/current-system/sw).

        Contains all packages that should be available system-wide.
      '';
    };

    environment.systemPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages to install in the system environment.";
      example = literalExpression "[ pkgs.vim pkgs.git ]";
    };
  };

  config = {
    system.build.toplevel = baseSystem;

    # Build system path from packages
    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = config.environment.systemPackages;
      pathsToLink = [
        "/bin"
        "/sbin"
        "/lib"
        "/share"
        "/etc"
      ];
    };

    # Essential system packages
    environment.systemPackages = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.systemd
      # Add more essential packages as needed
    ];
  };
}
