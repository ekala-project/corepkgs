# Adios port of ekaos/modules/config/xdg/sounds.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# XDG Sound Theme support
{ types, pkgs, ... }:

{
  options = {
    sounds = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = ''
            Whether to install files to support the XDG Sound Theme specification.
          '';
        };
      };
      description = "XDG sound theme settings.";
    };
  };

  impl =
    { options, ... }:
    if !options.sounds.enable then
      { }
    else
      {
        environment.systemPackages =
          if (pkgs ? sound-theme-freedesktop) then
            [
              pkgs.sound-theme-freedesktop
            ]
          else
            [ ];
      };
}
