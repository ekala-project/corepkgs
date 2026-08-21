# iproute2 configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.iproute2;
in

{
  options = {
    networking.iproute2 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable iproute2 configuration.

          When enabled, /etc/iproute2 configuration files are managed
          and custom routing tables can be defined.
        '';
      };

      rttablesExtraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          200 custom
          201 vpn
        '';
        description = ''
          Additional routing table entries appended to /etc/iproute2/rt_tables.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc."iproute2/rt_tables".text = ''
      # Reserved values
      255 local
      254 main
      253 default
      0   unspec

      # Local
      ${cfg.rttablesExtraConfig}
    '';
  };
}
