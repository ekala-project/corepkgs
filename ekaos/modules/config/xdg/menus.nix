# XDG Desktop Menu support
{
  config,
  lib,
  ...
}:

with lib;

{
  options = {
    xdg.menus.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to install files to support the XDG Desktop Menu specification.
      '';
    };
  };
}
