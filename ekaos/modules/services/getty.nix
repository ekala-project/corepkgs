# Adios port of ekaos/modules/services/getty.nix.
# TODO(adios-cutover): helpLine is declared but never consumed by the legacy
# config either; kept for interface stability.
{
  types,
  lib,
  pkgs,
  ...
}:

let
  # Generate getty service unit content for a single tty.
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
    enable = {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable getty (console login) on virtual terminals.

        When enabled, getty will spawn login prompts on tty1 through tty{ttyCount}.
      '';
    };

    ttyCount = {
      type = types.int;
      default = 6;
      description = ''
        Number of gettys to spawn on virtual terminals (tty1-ttyN).

        Defaults to 6, which provides login prompts on tty1 through tty6.
      '';
    };

    helpLine = {
      type = types.string;
      default = "";
      description = ''
        Additional help text to show on the login screen after the issue text.
      '';
    };
  };

  inputs = {
    # TODO(adios-cutover): verify leaf path once the service-managers batch lands.
    systemd.from = { root }: root."service-managers".systemd;
  };

  assertions = [
    {
      verify = { options }: options.ttyCount > 0;
      explain = { options }: "services.getty ttyCount must be positive, got ${toString options.ttyCount}";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        ttyNumbers = builtins.genList (i: 1 + i) options.ttyCount;
        unitFor = ttyNumber: {
          name = "systemd/system/getty@tty${toString ttyNumber}.service";
          value = {
            text = mkGettyUnit "tty${toString ttyNumber}";
          };
        };
        wantFor = ttyNumber: {
          name = "systemd/system/multi-user.target.wants/getty@tty${toString ttyNumber}.service";
          value = {
            # Placeholder - will be created by activation script
            source = "/dev/null";
          };
        };
      in
      {
        environment.etc = lib.merge.attrs.recursively {
          mutators = [
            (builtins.listToAttrs (builtins.map unitFor ttyNumbers))
            (builtins.listToAttrs (builtins.map wantFor ttyNumbers))
            {
              "systemd/system/systemd-vconsole-setup.service".source =
                "${inputs.systemd.package}/lib/systemd/system/systemd-vconsole-setup.service";

              "systemd/system/systemd-user-sessions.service".source =
                "${inputs.systemd.package}/lib/systemd/system/systemd-user-sessions.service";
            }
          ];
        };

        # TODO(adios-cutover): legacy ordering (after "etc") lost; plain script.
        system.activationScripts.getty = ''
          # Create getty service symlinks for multi-user.target
          mkdir -p /etc/systemd/system/multi-user.target.wants
          ${builtins.concatStringsSep "\n" (
            builtins.map (
              ttyNumber:
              let
                ttyName = "tty${toString ttyNumber}";
              in
              ''
                ln -sf ../getty@${ttyName}.service \
                       /etc/systemd/system/multi-user.target.wants/getty@${ttyName}.service
              ''
            ) ttyNumbers
          )}
        '';
      };
}
