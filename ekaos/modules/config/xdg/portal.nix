# Adios port of ekaos/modules/config/xdg/portal.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# XDG Desktop Portal support
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    portal = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable xdg-desktop-portal for sandboxed app integration.

            Portals allow sandboxed applications to interact with the system
            (file choosers, screenshots, screen sharing, etc.).
          '';
        };

        extraPortals = {
          type = types.listOf types.derivation;
          default = [ ];
          description = ''
            Portal implementation packages to install.

            At minimum, a desktop portal implementation should be listed
            (e.g. xdg-desktop-portal-gtk, xdg-desktop-portal-kde).
          '';
        };

        xdgOpenUsePortal = {
          type = types.bool;
          default = false;
          description = ''
            Whether xdg-open should use the portal to open programs.

            Resolves bugs with programs opening inside FHS environments
            or with unexpected environment variables.
          '';
        };

        config = {
          type = types.attrsOf (types.attrsOf (types.listOf types.string));
          default = { };
          example = {
            common = {
              default = [ "gtk" ];
            };
          };
          description = ''
            Portal backend configuration per desktop environment.

            Sets which portal backend provides the implementation for
            each requested interface. See portals.conf(5).
          '';
        };

        configPackages = {
          type = types.listOf types.derivation;
          default = [ ];
          description = ''
            Packages that provide XDG desktop portal configuration files.
          '';
        };
      };
      description = "XDG desktop portal settings.";
    };
  };

  impl =
    { options, ... }:
    if !options.portal.enable then
      { }
    else
      {
        environment.systemPackages = [
          (pkgs.xdg-desktop-portal or (throw "xdg-desktop-portal package not available"))
        ]
        ++ options.portal.extraPortals;

        environment.variables =
          if options.portal.xdgOpenUsePortal then
            {
              NIXOS_XDG_OPEN_USE_PORTAL = "1";
            }
          else
            { };

        # Generate portal config files
        environment.etc = lib.merge.attrs.recursively {
          mutators = builtins.map (
            desktop:
            let
              interfaces = options.portal.config.${desktop};
              filename =
                if desktop == "common" then
                  "xdg-desktop-portal/portals.conf"
                else
                  "xdg-desktop-portal/${desktop}-portals.conf";
              content = builtins.concatStringsSep "\n" (
                builtins.map (iface: "${iface}=${builtins.concatStringsSep ";" interfaces.${iface}}") (
                  builtins.attrNames interfaces
                )
              );
            in
            {
              "${filename}".text = ''
                [preferred]
                ${content}
              '';
            }
          ) (builtins.attrNames options.portal.config);
        };

        services.dbus.packages = [
          (pkgs.xdg-desktop-portal or (throw "xdg-desktop-portal package not available"))
        ]
        ++ options.portal.extraPortals;
      };
}
