# CI jobs, one attribute set per system: `x86_64-linux.hello`, ...
#
# iets evaluates in pure mode, where `builtins.currentSystem` does not exist,
# so every system to evaluate is listed explicitly. Add a system here to start
# evaluating (and building) its packages in CI.
{
  systems ? [ "x86_64-linux" ],
}:
let
  lib = import ../lib.nix { };
  mkPkgs = system: lib.recurseIntoAttrs (import ./packages.nix { inherit system; }).buildable;
  # For single system eval, avoid prefixing all attrs
  allSystems =
    if builtins.length systems == 1 then
      mkPkgs (builtins.head systems)
    else
      lib.recurseIntoAttrs (lib.genAttrs systems mkPkgs);
in
allSystems
