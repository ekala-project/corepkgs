# packages — extra packages for the dev shell (module-level)
#
# Usage in a module:
#   packages = [ pkgs.ripgrep pkgs.jq ];
{ lib, ... }:

{
  options.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Extra packages to include in the dev shell.";
  };
}
