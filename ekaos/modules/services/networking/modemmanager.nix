# Adios port of ekaos/modules/services/networking/modemmanager.nix.
#
# The legacy module declares two namespaces (networking.modemmanager and
# services.modem-manager); both are modelled as sub-option groups here and
# impl re-nests them into the legacy config shape.
# TODO(adios-cutover): command/args of services.modem-manager were internal
# options set by the legacy config; they are computed in impl.
{ types, pkgs, ... }:

{
  options = {
    modemmanager = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable ModemManager for managing modem devices.

            ModemManager is typically used by NetworkManager but can also
            be used standalone for non-IP modem connectivity (e.g. GPS).
          '';
        };

        package = {
          type = types.derivation;
          default = pkgs.modemmanager;
          description = "The ModemManager package to use.";
        };

        fccUnlockScripts = {
          # TODO(adios-cutover): submodule validation lost (id, path per entry).
          type = types.listOf types.attrs;
          default = [ ];
          description = ''
            List of FCC unlock scripts to enable on the system.
          '';
        };
      };
      description = "ModemManager networking options.";
    };

    service = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable the ModemManager service.";
        };

        description = {
          type = types.string;
          default = "ModemManager";
          description = "Service description.";
        };

        user = {
          type = types.string;
          default = "root";
          description = "User to run service as.";
        };

        restartPolicy = {
          type = types.string;
          default = "always";
          description = "Restart policy.";
        };

        systemd = {
          type = types.attrsOf types.any;
          default = { };
          description = "Systemd-specific options.";
        };
      };
      description = "ModemManager service interface options.";
    };
  };

  impl =
    { options, ... }:
    if !(options.modemmanager.enable or false) then
      { }
    else
      let
        mm = options.modemmanager;
        svc = options.service or { };
      in
      {
        environment.etc = builtins.listToAttrs (
          builtins.map (e: {
            name = "ModemManager/fcc-unlock.d/${e.id}";
            value = {
              source = e.path;
            };
          }) (mm.fccUnlockScripts or [ ])
        );

        services.modem-manager = {
          enable = true;
          description = svc.description or "ModemManager";
          command = "${mm.package}/bin/ModemManager";
          args = [ "--no-daemon" ];
          user = svc.user or "root";
          restartPolicy = svc.restartPolicy or "always";
          systemd = {
            after = [
              "dbus.service"
              "polkit.service"
            ];
            wantedBy = [ "multi-user.target" ];
          }
          // (svc.systemd or { });
        };

        environment.systemPackages = [
          mm.package
        ]
        ++ (
          if (mm.fccUnlockScripts or [ ]) != [ ] then
            [
              pkgs.libqmi
              pkgs.libmbim
            ]
          else
            [ ]
        );

        services.dbus.packages = [ mm.package ];
        services.udev.packages = [ mm.package ];

        security.polkit.enable = true;
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (
              subject.isInGroup("networkmanager")
              && action.id.indexOf("org.freedesktop.ModemManager") == 0
              )
                { return polkit.Result.YES; }
          });
        '';
      };
}
