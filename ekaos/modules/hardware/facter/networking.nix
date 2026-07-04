# Auto-configure network interfaces for DHCP based on detected hardware
{ config, lib, ... }:
let
  # Filter to physical network interfaces suitable for DHCP
  physicalInterfaces = lib.filter (
    iface:
    let
      validTypes = [
        "Ethernet"
        "WLAN"
        "USB-Link"
        "Network Interface"
      ];
    in
    lib.elem (iface.sub_class.name or "") validTypes
  ) (config.hardware.facter.report.hardware.network_interface or [ ]);

  detectedInterfaceNames = lib.concatMap (iface: iface.unix_device_names or [ ]) physicalInterfaces;
  interfaceNames = config.hardware.facter.detected.dhcp.interfaces;

  perInterfaceConfig = lib.listToAttrs (
    lib.map (name: {
      inherit name;
      value = {
        useDHCP = lib.mkDefault true;
      };
    }) interfaceNames
  );
in
{
  options.hardware.facter.detected.dhcp = {
    enable = lib.mkEnableOption "Facter DHCP auto-configuration" // {
      default = builtins.length (config.hardware.facter.report.hardware.network_interface or [ ]) > 0;
      defaultText = "hardware dependent";
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = detectedInterfaceNames;
      defaultText = "auto-detected from facter report";
      description = "Network interfaces to configure with DHCP.";
      example = [
        "eth0"
        "wlan0"
      ];
    };
  };

  config = lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.dhcp.enable) {
    networking.useDHCP = lib.mkDefault true;
    networking.interfaces = perInterfaceConfig;
  };
}
