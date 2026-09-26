# Adios port of ekaos/modules/boot/systemd-boot.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    # Legacy path: boot.loader.grub.enable (compat; GRUB unsupported).
    grubEnable = {
      type = types.bool;
      default = false;
      description = "GRUB is not supported in ekaos. Use systemd-boot instead.";
    };

    # Legacy path: boot.loader.limine.enable (compat; Limine unsupported).
    limineEnable = {
      type = types.bool;
      default = false;
      description = "Limine is not supported in ekaos. Use systemd-boot instead.";
    };

    # Legacy path: boot.loader.systemd-boot.enable.
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the systemd-boot (formerly gummiboot) UEFI boot loader.

        This boot loader is simple and lightweight, suitable for UEFI systems.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.sortKey.
    sortKey = {
      type = types.string;
      default = "ekaos";
      description = ''
        Sort key for boot entries.

        Controls the order in which entries appear in the boot menu.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.timeout.
    timeout = {
      type = types.nullOr types.int;
      default = 5;
      description = ''
        Boot menu timeout in seconds.

        null means wait indefinitely for user input.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.editor.
    editor = {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow editing boot parameters in the boot menu.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.configurationLimit.
    configurationLimit = {
      type = types.int;
      default = 20;
      description = ''
        Maximum number of boot configurations to keep.

        Older configurations will be automatically cleaned up.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.consoleMode.
    consoleMode = {
      type = types.enum "systemdBootConsoleMode" [
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

    # Legacy path: boot.loader.systemd-boot.graceful.
    graceful = {
      type = types.bool;
      default = false;
      description = ''
        Continue even if some operations fail.

        Useful for troubleshooting boot loader issues.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.memtest86.enable.
    memtest86Enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to add a memtest86+ entry to the systemd-boot menu.

        Requires the memtest86plus package.
      '';
    };

    # Legacy path: boot.loader.systemd-boot.extraInstallCommands.
    extraInstallCommands = {
      type = types.string;
      default = "";
      description = ''
        Additional commands to run after installing the boot loader.
      '';
    };

    # Legacy path: boot.loader.efi.canTouchEfiVariables.
    efiCanTouchEfiVariables = {
      type = types.bool;
      default = true;
      description = ''
        Whether the system can modify EFI boot variables.

        Needed for proper boot loader installation.
      '';
    };

    # Legacy path: boot.loader.efi.efiSysMountPoint.
    efiSysMountPoint = {
      type = types.string;
      default = "/boot";
      description = ''
        Where the EFI System Partition (ESP) is mounted.
      '';
    };

    # Legacy path: boot.loader.efi.type.
    efiType = {
      type = types.listOf (
        types.enum "efiEntryType" [
          "efi"
          "uki"
        ]
      );
      default = [ "efi" ];
      description = ''
        Boot entry types to install.

        - "efi": Traditional BLS Type #1 entries with separate kernel/initrd files
          and .conf entry files. This is the default and current behavior.
        - "uki": Unified Kernel Image — a single .efi PE binary per generation
          bundling the EFI stub, kernel, initrd, and command line.
      '';
    };

    # Legacy internal option system.build.installBootLoader is folded into
    # impl below (it is a computed output, not an input).
  };

  inputs = {
    # TODO(adios-cutover): provides systemd.package (defined in
    # ekaos/modules/system/toplevel.nix); flat leaf name pending the
    # system/toplevel port — full legacy path used below.
    systemd.from = { root }: root.system.toplevel;
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        systemdBootBuilder = pkgs.substituteAll {
          # Resolves once ekaos/lib/systemd-boot-builder.py is mirrored at
          # ekaos/adios/lib/systemd-boot-builder.py (NON-MODULE verbatim copy).
          src = ../../lib/systemd-boot-builder.py;
          isExecutable = true;

          inherit (pkgs) python3;
          systemd = inputs.systemd.systemd.package;
          nix = pkgs.nix;
          timeout = options.timeout;
          editor = if options.editor then "True" else "False";
          configurationLimit = options.configurationLimit;
          inherit (options) consoleMode graceful;

          efi = {
            inherit (options) efiCanTouchEfiVariables efiSysMountPoint;
          };
          efiType = builtins.toJSON options.efiType;

          bootspecTools = pkgs.writeScriptBin "synthesize" ''
            #!${pkgs.runtimeShell}
            # Placeholder for bootspec synthesize tool
            # For now, just pass through the boot.json
            cat "$@"
          '';
        };

        # Legacy appended this to its own extraInstallCommands option when
        # memtest86 was enabled; the merged value is computed here.
        memtestCommands =
          if options.memtest86Enable then
            let
              memtest = pkgs.memtest86plus or (throw "memtest86plus package not available");
            in
            ''
              # Copy memtest86+ binary
              mkdir -p ${options.efiSysMountPoint}/EFI/memtest86
              cp ${memtest}/memtest.efi ${options.efiSysMountPoint}/EFI/memtest86/memtest.efi 2>/dev/null || true

              # Create boot entry
              mkdir -p ${options.efiSysMountPoint}/loader/entries
              cat > ${options.efiSysMountPoint}/loader/entries/memtest86.conf <<MEMEOF
              title   Memtest86+
              efi     /EFI/memtest86/memtest.efi
              MEMEOF
            ''
          else
            "";
        extraInstallCommands = options.extraInstallCommands + memtestCommands;
      in
      {
        # Legacy internal option system.build.installBootLoader.
        system.build.installBootLoader = pkgs.writeScript "install-systemd-boot.sh" ''
          #!${pkgs.runtimeShell}
          set -e

          # The systemd-boot-builder.py script expects the system path as argument
          ${systemdBootBuilder} "$@"

          ${extraInstallCommands}
        '';

        # Legacy set boot.loader.systemd-boot.sortKey = mkDefault "ekaos" here;
        # identical to the option default above, so no impl output (no-op).

        boot.loader.systemd-boot.extraInstallCommands = extraInstallCommands;

        environment.systemPackages = [ inputs.systemd.systemd.package ];
      };
}
