# systemd-boot UEFI boot loader configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.loader.systemd-boot;

  # Wrap the systemd-boot-builder.py script with substitutions
  systemdBootBuilder = pkgs.substituteAll {
    src = ../../lib/systemd-boot-builder.py;
    isExecutable = true;

    inherit (pkgs) python3;
    systemd = config.systemd.package;
    nix = pkgs.nix;
    timeout = cfg.timeout;
    editor = if cfg.editor then "True" else "False";
    configurationLimit = cfg.configurationLimit;
    inherit (cfg) consoleMode graceful;

    inherit (config.boot.loader) efi;
    efiType = builtins.toJSON config.boot.loader.efi.type;

    # bootspec tools (may need to be created or imported)
    bootspecTools = pkgs.writeScriptBin "synthesize" ''
      #!${pkgs.runtimeShell}
      # Placeholder for bootspec synthesize tool
      # For now, just pass through the boot.json
      cat "$@"
    '';
  };

in

{
  options = {
    # Compatibility options for nixpkgs make-disk-image.nix
    boot.loader.grub.enable = mkOption {
      type = types.bool;
      default = false;
      description = "GRUB is not supported in ekaos. Use systemd-boot instead.";
    };

    boot.loader.limine.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Limine is not supported in ekaos. Use systemd-boot instead.";
    };

    boot.loader.systemd-boot = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the systemd-boot (formerly gummiboot) UEFI boot loader.

          This boot loader is simple and lightweight, suitable for UEFI systems.
        '';
      };

      sortKey = mkOption {
        type = types.str;
        default = "ekaos";
        description = ''
          Sort key for boot entries.

          Controls the order in which entries appear in the boot menu.
        '';
      };

      timeout = mkOption {
        type = types.nullOr types.int;
        default = 5;
        description = ''
          Boot menu timeout in seconds.

          null means wait indefinitely for user input.
        '';
      };

      editor = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to allow editing boot parameters in the boot menu.
        '';
      };

      configurationLimit = mkOption {
        type = types.int;
        default = 20;
        description = ''
          Maximum number of boot configurations to keep.

          Older configurations will be automatically cleaned up.
        '';
      };

      consoleMode = mkOption {
        type = types.enum [
          "auto"
          "max"
          "keep"
        ];
        default = "keep";
        description = ''
          Console mode for the boot loader.

          - auto: Set to maximum available
          - max: Same as auto
          - keep: Keep current mode
        '';
      };

      graceful = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Continue even if some operations fail.

          Useful for troubleshooting boot loader issues.
        '';
      };

      extraInstallCommands = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional commands to run after installing the boot loader.
        '';
      };
    };

    boot.loader.efi = {
      canTouchEfiVariables = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether the system can modify EFI boot variables.

          Needed for proper boot loader installation.
        '';
      };

      efiSysMountPoint = mkOption {
        type = types.str;
        default = "/boot";
        description = ''
          Where the EFI System Partition (ESP) is mounted.
        '';
      };

      type = mkOption {
        type = types.listOf (types.enum [ "efi" "uki" ]);
        default = [ "efi" ];
        description = ''
          Boot entry types to install.

          - "efi": Traditional BLS Type #1 entries with separate kernel/initrd files
            and .conf entry files. This is the default and current behavior.
          - "uki": Unified Kernel Image — a single .efi PE binary per generation
            bundling the EFI stub, kernel, initrd, and command line. Discovered
            by systemd-boot via Type #2 autodiscovery in /EFI/Linux/.

          Both can be specified simultaneously for dual boot entries.
        '';
      };
    };

    system.build.installBootLoader = mkOption {
      type = types.package;
      internal = true;
      description = "Script to install the boot loader.";
    };
  };

  config = mkIf cfg.enable {
    # Build the boot loader installer script
    system.build.installBootLoader = pkgs.writeScript "install-systemd-boot.sh" ''
      #!${pkgs.runtimeShell}
      set -e

      # The systemd-boot-builder.py script expects the system path as argument
      ${systemdBootBuilder} "$@"

      ${cfg.extraInstallCommands}
    '';

    # Ensure systemd-boot extensions are added to bootspec
    # (This will be used by systemd-boot-builder.py)
    boot.loader.systemd-boot.sortKey = mkDefault "ekaos";

    # Add systemd-boot to system packages for bootctl command
    environment.systemPackages = [ config.systemd.package ];
  };
}
