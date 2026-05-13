# Getty (console login) service
# Provides console login on virtual terminals
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.getty;

  # Generate getty service unit content for a single tty
  mkGettyUnit = ttyName: ''
    [Unit]
    Description=Getty on ${ttyName}
    Documentation=man:agetty(8) man:systemd-getty-generator(8)
    After=systemd-user-sessions.service plymouth-quit-wait.service systemd-vconsole-setup.service
    Requires=systemd-vconsole-setup.service

    [Service]
    ExecStart=-${pkgs.util-linux}/bin/agetty --noclear --keep-baud ${ttyName} 115200,38400,9600 $TERM
    Type=idle
    Restart=always
    RestartSec=0
    UtmpIdentifier=${ttyName}
    TTYPath=/dev/${ttyName}
    TTYReset=yes
    TTYVHangup=yes
    TTYVTDisallocate=yes
    KillMode=process
    IgnoreSIGPIPE=no
    SendSIGHUP=yes

    # Security hardening
    CapabilityBoundingSet=CAP_SYS_ADMIN CAP_SYS_TTY_CONFIG CAP_SETGID CAP_SYS_CHROOT CAP_CHOWN CAP_DAC_OVERRIDE
    NoNewPrivileges=yes
    PrivateTmp=yes

    [Install]
    WantedBy=multi-user.target
  '';

in

{
  options = {
    services.getty = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable getty (console login) on virtual terminals.

          When enabled, getty will spawn login prompts on tty1 through tty{ttyCount}.
        '';
      };

      ttyCount = mkOption {
        type = types.ints.positive;
        default = 6;
        description = ''
          Number of gettys to spawn on virtual terminals (tty1-ttyN).

          Defaults to 6, which provides login prompts on tty1 through tty6.
        '';
      };

      helpLine = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional help text to show on the login screen after the issue text.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Inject getty service unit files directly into /etc/systemd/system
    environment.etc = mkMerge [
      # Create getty service units for each tty
      (listToAttrs (
        map (ttyNumber: let
          ttyName = "tty${toString ttyNumber}";
        in
          nameValuePair "systemd/system/getty@${ttyName}.service" {
            text = mkGettyUnit ttyName;
          }
        ) (range 1 cfg.ttyCount)
      ))

      # Create symlinks in wants directory to auto-start gettys
      (listToAttrs (
        map (ttyNumber: let
          ttyName = "tty${toString ttyNumber}";
        in
          nameValuePair "systemd/system/multi-user.target.wants/getty@${ttyName}.service" {
            source = "/dev/null"; # Placeholder - will be created by activation script
          }
        ) (range 1 cfg.ttyCount)
      ))

      # Ensure required systemd services are available
      {
        "systemd/system/systemd-vconsole-setup.service".source =
          "${config.systemd.package}/lib/systemd/system/systemd-vconsole-setup.service";

        "systemd/system/systemd-user-sessions.service".source =
          "${config.systemd.package}/lib/systemd/system/systemd-user-sessions.service";
      }
    ];

    # Add activation script to create getty service symlinks
    system.activationScripts.getty = stringAfter [ "etc" ] ''
      # Create getty service symlinks for multi-user.target
      mkdir -p /etc/systemd/system/multi-user.target.wants
      ${concatMapStringsSep "\n" (ttyNumber: let
        ttyName = "tty${toString ttyNumber}";
      in ''
        ln -sf ../getty@${ttyName}.service \
               /etc/systemd/system/multi-user.target.wants/getty@${ttyName}.service
      '') (range 1 cfg.ttyCount)}
    '';
  };
}
