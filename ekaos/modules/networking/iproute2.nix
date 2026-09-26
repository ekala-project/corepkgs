# Adios port of ekaos/modules/networking/iproute2.nix.
#
# Tree path: networking/iproute2 is parent.networking.iproute2.
# Self-contained; no cross-module reads.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable iproute2 configuration.

        When enabled, /etc/iproute2 configuration files are managed
        and custom routing tables can be defined.
      '';
    };

    rttablesExtraConfig = {
      type = types.string;
      default = "";
      example = ''
        200 custom
        201 vpn
      '';
      description = "Additional routing table entries appended to /etc/iproute2/rt_tables.";
    };
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        environment.etc."iproute2/rt_tables".text = ''
          # Reserved values
          255 local
          254 main
          253 default
          0   unspec

          # Local
          ${options.rttablesExtraConfig}
        '';
      };
}
