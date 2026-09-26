# Adios port of ekaos/modules/services/hardware/fprintd.nix.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable fprintd daemon for fingerprint reader support.";
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.fprintd or null;
      description = "The fprintd package to use.";
    };

    tod = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable Touch OEM Drivers library support.";
        };

        driver = {
          type = types.derivation;
          description = "Touch OEM Drivers (TOD) package to use.";
        };
      };
      description = "Touch OEM Drivers (TOD) configuration.";
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain = { options, ... }: "package option must be set when enabled (fprintd is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        fprintdPkg = if (options.tod.enable or false) then pkgs.fprintd-tod else options.package;
      in
      {
        services.dbus.packages = [ fprintdPkg ];
        environment.systemPackages = [ fprintdPkg ];

        # TODO: systemd.packages not yet available in ekaOS
        # systemd.packages = [ fprintdPkg ];
      };
}
