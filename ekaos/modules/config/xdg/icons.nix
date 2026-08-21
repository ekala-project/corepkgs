# XDG Icon Theme support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.xdg.icons;
in

{
  options = {
    xdg.icons = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to install files to support the XDG Icon Theme specification.
        '';
      };

      fallbackCursorThemes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Fallback cursor theme names, in order of preference.
          Set to [] to disable the fallback entirely.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkIf (pkgs ? hicolor-icon-theme) [
      pkgs.hicolor-icon-theme
    ];

    environment.variables.XCURSOR_PATH = mkDefault (
      concatStringsSep ":" [
        "$HOME/.icons"
        "$HOME/.local/share/icons"
        "/run/current-system/sw/share/icons"
        "/run/current-system/sw/share/pixmaps"
      ]
    );
  };
}
