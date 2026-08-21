# XDG Autostart support
{
  config,
  lib,
  ...
}:

with lib;

{
  options = {
    xdg.autostart = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable auto-starting of desktop applications
          according to the XDG Autostart specification.
        '';
      };

      install = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to install .desktop files from system packages
          into /etc/xdg/autostart/.
        '';
      };
    };
  };
}
