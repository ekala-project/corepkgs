# Adios port of ekaos/modules/services.nix.
#
# The legacy module defines no options and no config; it only documents the
# cross-platform service interface (enable/description/command/args/user/
# group/restartPolicy/systemd/settings) that individual service modules
# provide and that the service-managers consume.
{ ... }:

{
  options = { };

  impl = { ... }: { };
}
