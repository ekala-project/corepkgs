# treefmt — one CLI to format the whole tree
#
# Usage:
#   treefmt.enable = true;
{ lib, ... }:

{
  options.treefmt = {
    enable = lib.mkEnableOption "treefmt, a unified code formatter";
  };
}
