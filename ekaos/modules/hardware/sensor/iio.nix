# IIO sensor support (accelerometer, gyroscope, ambient light)
# Ported from nixpkgs/nixos/modules/hardware/sensor/iio.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.sensor.iio;
in
{
  options.hardware.sensor.iio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable IIO sensor support with iio-sensor-proxy.

        IIO sensors are used for screen orientation and ambient light
        on tablets, convertibles, and some laptops.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.iio-sensor-proxy or (throw "iio-sensor-proxy package not available");
      defaultText = lib.literalExpression "pkgs.iio-sensor-proxy";
      description = "The iio-sensor-proxy package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "hid-sensor-hub" ];

    environment.systemPackages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];

    # TODO: services.udev.packages not yet available in ekaOS
    # services.udev.packages = [ cfg.package ];
  };
}
