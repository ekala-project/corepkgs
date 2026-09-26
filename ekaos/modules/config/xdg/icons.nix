# Adios port of ekaos/modules/config/xdg/icons.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# XDG Icon Theme support
{ types, pkgs, ... }:

{
  options = {
    icons = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = ''
            Whether to install files to support the XDG Icon Theme specification.
          '';
        };

        fallbackCursorThemes = {
          type = types.listOf types.string;
          default = [ ];
          description = ''
            Fallback cursor theme names, in order of preference.
            Set to [] to disable the fallback entirely.
          '';
        };
      };
      description = "XDG icon theme settings.";
    };
  };

  impl =
    { options, ... }:
    if !options.icons.enable then
      { }
    else
      {
        environment.systemPackages =
          if (pkgs ? hicolor-icon-theme) then
            [
              pkgs.hicolor-icon-theme
            ]
          else
            [ ];

        # TODO(adios-cutover): priority lost (was mkDefault).
        environment.variables.XCURSOR_PATH = builtins.concatStringsSep ":" [
          "$HOME/.icons"
          "$HOME/.local/share/icons"
          "/run/current-system/sw/share/icons"
          "/run/current-system/sw/share/pixmaps"
        ];
      };
}
