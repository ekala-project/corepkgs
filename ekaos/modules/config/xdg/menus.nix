# Adios port of ekaos/modules/config/xdg/menus.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# XDG Desktop Menu support. This module declares options only; it has no
# config section.
{ types, ... }:

{
  options = {
    menus = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = ''
            Whether to install files to support the XDG Desktop Menu specification.
          '';
        };
      };
      description = "XDG desktop menu settings.";
    };
  };

  impl = { ... }: { };
}
