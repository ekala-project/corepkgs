# ModemManager service module
# Provides WWAN modem management, typically used with NetworkManager
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.modemmanager;
in

{
  options = {
    networking.modemmanager = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable ModemManager for managing modem devices.

          ModemManager is typically used by NetworkManager but can also
          be used standalone for non-IP modem connectivity (e.g. GPS).
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.modemmanager;
        defaultText = literalExpression "pkgs.modemmanager";
        description = "The ModemManager package to use.";
      };

      fccUnlockScripts = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              id = mkOption {
                type = types.str;
                description = "vid:pid of the PCI or USB vendor and product ID.";
              };
              path = mkOption {
                type = types.path;
                description = "Path to the unlock script.";
              };
            };
          }
        );
        default = [ ];
        description = ''
          List of FCC unlock scripts to enable on the system.
        '';
      };
    };

    # Service interface options
    services.modem-manager = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the ModemManager service.";
      };

      description = mkOption {
        type = types.str;
        default = "ModemManager";
        description = "Service description.";
      };

      command = mkOption {
        type = types.str;
        internal = true;
        description = "Command to run (set automatically).";
      };

      args = mkOption {
        type = types.listOf types.str;
        internal = true;
        default = [ ];
        description = "Command arguments (set automatically).";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User to run service as.";
      };

      restartPolicy = mkOption {
        type = types.str;
        default = "always";
        description = "Restart policy.";
      };

      systemd = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Systemd-specific options.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc = listToAttrs (
      map (
        e:
        nameValuePair "ModemManager/fcc-unlock.d/${e.id}" {
          source = e.path;
        }
      ) cfg.fccUnlockScripts
    );

    services.modem-manager = {
      enable = true;
      command = "${cfg.package}/bin/ModemManager";
      args = [ "--no-daemon" ];
      user = "root";
      restartPolicy = "always";

      systemd = {
        after = [
          "dbus.service"
          "polkit.service"
        ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    environment.systemPackages = [
      cfg.package
    ]
    ++ optionals (cfg.fccUnlockScripts != [ ]) [
      pkgs.libqmi
      pkgs.libmbim
    ];

    services.dbus.packages = [ cfg.package ];
    # TODO: services.udev.packages not yet available in EkaOS
    # services.udev.packages = [ cfg.package ];

    # TODO: security.polkit not yet available in EkaOS
    # security.polkit.enable = true;
    # security.polkit.extraConfig = ''
    #   polkit.addRule(function(action, subject) {
    #     if (
    #       subject.isInGroup("networkmanager")
    #       && action.id.indexOf("org.freedesktop.ModemManager") == 0
    #       )
    #         { return polkit.Result.YES; }
    #   });
    # '';
  };
}
