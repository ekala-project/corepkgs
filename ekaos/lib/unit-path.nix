# The PATH line for a generated systemd service.
#
# ekaos has no /usr, so systemd's built-in default PATH finds nothing.
# Like NixOS, every unit gets coreutils, findutils, grep, sed and
# systemd, then the unit's own packages, then the system profile.
# A unit that sets PATH in its environment keeps its own.
{
  lib,
  pkgs,
  systemd,
}:

let
  defaultPackages = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    systemd
  ];
in
{
  inherit defaultPackages;

  environmentLine =
    {
      packages ? [ ],
      environment ? { },
    }:
    let
      all = packages ++ defaultPackages;
    in
    lib.optionalString (!(environment ? PATH))
      "Environment=\"PATH=${
        lib.concatStringsSep ":" [
          (lib.makeBinPath all)
          (lib.makeSearchPathOutput "bin" "sbin" all)
          "/run/wrappers/bin"
          "/run/current-system/sw/bin"
          "/run/current-system/sw/sbin"
        ]
      }\"";
}
