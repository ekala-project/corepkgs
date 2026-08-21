# Plymouth boot splash screen
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.plymouth;
in

{
  options = {
    boot.plymouth = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Plymouth boot splash screen.

          Plymouth provides a graphical boot animation that hides
          the text-mode boot messages.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.plymouth or (throw "plymouth package not available in core-pkgs");
        defaultText = literalExpression "pkgs.plymouth";
        description = "The Plymouth package to use.";
      };

      theme = mkOption {
        type = types.str;
        default = "bgrt";
        example = "spinner";
        description = ''
          Plymouth splash screen theme name.
        '';
      };

      themePackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra theme packages for Plymouth.";
      };

      logo = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Logo displayed on the splash screen (PNG format).
        '';
      };

      font = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Font file for displaying text on the splash screen.";
      };

      showDelay = mkOption {
        type = types.int;
        default = 0;
        example = 1;
        description = "Time (in seconds) to delay the splash screen.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional configuration lines for plymouthd.conf.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Add "splash" to kernel parameters
    boot.kernelParams = [ "splash" ];

    environment.systemPackages = [ cfg.package ] ++ cfg.themePackages;

    environment.etc."plymouth/plymouthd.conf".text = ''
      [Daemon]
      Theme=${cfg.theme}
      ShowDelay=${toString cfg.showDelay}
      ${optionalString (cfg.logo != null) "Logo=${cfg.logo}"}
      ${cfg.extraConfig}
    '';

    system.activationScripts.plymouth = stringAfter [ "etc" ] ''
      mkdir -p /var/lib/plymouth
      mkdir -p /var/log
      mkdir -p /run/plymouth
    '';
  };
}
