# XDG Desktop Portal support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.xdg.portal;

  # Association type for portal config
  associationType = types.attrsOf (types.listOf types.str);

in

{
  options = {
    xdg.portal = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable xdg-desktop-portal for sandboxed app integration.

          Portals allow sandboxed applications to interact with the system
          (file choosers, screenshots, screen sharing, etc.).
        '';
      };

      extraPortals = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = ''
          Portal implementation packages to install.

          At minimum, a desktop portal implementation should be listed
          (e.g. xdg-desktop-portal-gtk, xdg-desktop-portal-kde).
        '';
      };

      xdgOpenUsePortal = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether xdg-open should use the portal to open programs.

          Resolves bugs with programs opening inside FHS environments
          or with unexpected environment variables.
        '';
      };

      config = mkOption {
        type = types.attrsOf associationType;
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

      configPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = ''
          Packages that provide XDG desktop portal configuration files.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.xdg-desktop-portal or (throw "xdg-desktop-portal package not available"))
    ]
    ++ cfg.extraPortals;

    environment.variables = mkIf cfg.xdgOpenUsePortal {
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
    };

    # Generate portal config files
    environment.etc = mkMerge (
      mapAttrsToList (
        desktop: interfaces:
        let
          filename =
            if desktop == "common" then
              "xdg-desktop-portal/portals.conf"
            else
              "xdg-desktop-portal/${desktop}-portals.conf";
          content = concatStringsSep "\n" (
            mapAttrsToList (iface: impls: "${iface}=${concatStringsSep ";" impls}") interfaces
          );
        in
        {
          "${filename}".text = ''
            [preferred]
            ${content}
          '';
        }
      ) cfg.config
    );

    services.dbus.packages = [
      (pkgs.xdg-desktop-portal or (throw "xdg-desktop-portal package not available"))
    ]
    ++ cfg.extraPortals;
  };
}
