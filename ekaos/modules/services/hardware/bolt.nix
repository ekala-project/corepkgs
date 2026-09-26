# Adios port of ekaos/modules/services/hardware/bolt.nix.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Bolt, a userspace daemon to enable
        security levels for Thunderbolt 3 on GNU/Linux.
      '';
    };

    package = {
      type = types.derivation;
      default = pkgs.bolt or (throw "bolt package not available");
      description = "The bolt package to use.";
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        environment.systemPackages = [ options.package ];
        services.udev.packages = [ options.package ];

        # TODO: systemd.packages not yet available in ekaOS
        # systemd.packages = [ options.package ];
      };
}
