# Adios port of ekaos/modules/hardware/facter/networking.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.network_interface or [ ]) > 0;
      description = "Whether to enable Facter DHCP auto-configuration.";
    };

    interfaces = {
      type = types.listOf types.string;
      defaultFunc =
        { inputs, ... }:
        let
          validTypes = [
            "Ethernet"
            "WLAN"
            "USB-Link"
            "Network Interface"
          ];
          physicalInterfaces = builtins.filter (
            iface: builtins.elem (iface.sub_class.name or "") validTypes
          ) (inputs.facter.report.hardware.network_interface or [ ]);
        in
        builtins.concatMap (iface: iface.unix_device_names or [ ]) physicalInterfaces;
      description = "Network interfaces to configure with DHCP.";
      example = [
        "eth0"
        "wlan0"
      ];
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost (both options).
        networking.useDHCP = true;
        networking.interfaces = builtins.listToAttrs (
          builtins.map (name: {
            inherit name;
            value = {
              useDHCP = true;
            };
          }) options.interfaces
        );
      }
    else
      { };
}
