# ekaos system configuration evaluation (adios-based)
#
# Entry point for building ekaos systems.
#
# Usage:
#
#   (import ./eval-config.nix { inherit lib pkgs adios; }) {
#     modules = [ <extra adios modules> ];
#     overrides = {
#       # Per-module option overrides, keyed by tree path:
#       options."/boot/kernel" = { kernelParams = [ "quiet" ]; };
#       options."/services/getty" = { ttyCount = 4; };
#     };
#     extraConfig = {
#       # Legacy-shape fragment merged last (wins). Use ONLY for pure
#       # accumulator paths no module owns (environment.systemPackages,
#       # environment.etc, networking.extraHosts, ...). Paths owned by a
#       # module's options MUST go through `overrides`, otherwise the owning
#       # module's impl will not see them.
#     };
#   };
{ lib, pkgs, adios }:

{
  modules ? [ ],
  overrides ? { },
  extraConfig ? { },
  ...
}@args:

let
  baseModules = import ./adios/modules-tree.nix { inherit adios pkgs; };

  rootDef = adios.lib.inject ([ { modules = baseModules; } ] ++ modules);

  tree = (adios rootDef) overrides;

  # Collect impl fragments from every module in the tree.
  collect =
    mods:
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          n: m:
          (if m ? __functor then [ (m { }) ] else [ ])
          ++ (if m ? modules then collect m.modules else [ ])
        ) mods
      )
    );

  fragments = collect tree.modules;

  # NixOS-like fragment merge: attrsets recurse, lists concatenate,
  # anything else takes the later value. (adios's own merge helpers throw
  # on duplicate leaves, which every multi-module config has.)
  isDrv = x: builtins.isAttrs x && ((x.type or "") == "derivation" || x ? outPath);
  mergeTwo =
    a: b:
    if builtins.isAttrs a && builtins.isAttrs b && !isDrv a && !isDrv b then
      a
      // b
      // builtins.listToAttrs (
        map (k: {
          name = k;
          value = mergeTwo a.${k} b.${k};
        }) (builtins.filter (k: builtins.hasAttr k a) (builtins.attrNames b))
      )
    else if builtins.isList a && builtins.isList b then
      a ++ b
    else
      b;
  config = builtins.foldl' mergeTwo { } (fragments ++ [ extraConfig ]);

in

{
  inherit config tree;

  # Expose the system closure for building (best-effort: impl-output
  # aggregation gaps are documented in adios/README.md).
  system = config.system.build.toplevel or null;

  # Legacy-shape pass-throughs for consumers.
  bootStage2 = config.system.build.bootStage2 or null;
  activationScript = config.system.build.activationScript or null;
  etc = config.system.build.etc or null;
  vm = config.system.build.vm or null;
}
