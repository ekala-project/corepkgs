# Adios port of ekaos/modules/hardware/sensor/iio.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Enable IIO sensor support with iio-sensor-proxy.

        IIO sensors are used for screen orientation and ambient light
        on tablets, convertibles, and some laptops.
      '';
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.iio-sensor-proxy or null;
      description = "The iio-sensor-proxy package to use.";
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain =
        { options, ... }: "package option must be set when enabled (iio-sensor-proxy is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if options.enable then
      {
        boot.initrd.availableKernelModules = [ "hid-sensor-hub" ];

        environment.systemPackages = [ options.package ];
        services.dbus.packages = [ options.package ];

        services.udev.packages = [ options.package ];
      }
    else
      { };
}
