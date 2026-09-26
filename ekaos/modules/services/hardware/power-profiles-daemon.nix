# Adios port of ekaos/modules/services/hardware/power-profiles-daemon.nix.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable power-profiles-daemon, a D-Bus daemon that allows
        changing system behavior based upon user-selected power profiles.
      '';
    };

    package = {
      type = types.derivation;
      default = pkgs.power-profiles-daemon or (throw "power-profiles-daemon package not available");
      description = "The power-profiles-daemon package to use.";
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        environment.systemPackages = [ options.package ];
        services.dbus.packages = [ options.package ];
        services.udev.packages = [ options.package ];

        # TODO: systemd.packages not yet available in ekaOS
        # systemd.packages = [ options.package ];
      };
}
