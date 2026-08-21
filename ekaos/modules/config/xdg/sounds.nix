# XDG Sound Theme support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.xdg.sounds;
in

{
  options = {
    xdg.sounds.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to install files to support the XDG Sound Theme specification.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkIf (pkgs ? sound-theme-freedesktop) [
      pkgs.sound-theme-freedesktop
    ];
  };
}
