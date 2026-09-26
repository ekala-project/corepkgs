# Adios port of ekaos/modules/config/xdg/autostart.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# XDG Autostart support. This module declares options only; it has no
# config section.
{ types, ... }:

{
  options = {
    autostart = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = ''
            Whether to enable auto-starting of desktop applications
            according to the XDG Autostart specification.
          '';
        };

        install = {
          type = types.bool;
          default = true;
          description = ''
            Whether to install .desktop files from system packages
            into /etc/xdg/autostart/.
          '';
        };
      };
      description = "XDG autostart settings.";
    };
  };

  impl = { ... }: { };
}
