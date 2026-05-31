# The `splicedPackages' package set, and its use by `callPackage`
#
# The `buildPackages` pkg set is a new concept, and the vast majority package
# expression (the other *.nix files) are not designed with it in mind. This
# presents us with a problem with how to get the right version (build-time vs
# run-time) of a package to a consumer that isn't used to thinking so cleverly.
#
# The solution is to splice the package sets together as we do below, so every
# `callPackage`d expression in fact gets both versions. Each derivation (and
# each derivation's outputs) consists of the run-time version, augmented with
# a `__spliced.buildHost` field for the build-time version, and
# `__spliced.hostTarget` field for the run-time version.
#
# For performance reasons, rather than uniformally splice in all cases, we only
# do so when `pkgs` and `buildPackages` are distinct. The `actuallySplice`
# parameter there the boolean value of that equality check.
lib: pkgs: actuallySplice:

let
  # These functions are used by nixpkgs' lib.customisation but not yet available
  # in our pinned nix-lib. Define them locally until the pin is updated.
  mapCrossIndex =
    f:
    {
      buildBuild,
      buildHost,
      buildTarget,
      hostHost,
      hostTarget,
      targetTarget,
    }:
    {
      buildBuild = f buildBuild;
      buildHost = f buildHost;
      buildTarget = f buildTarget;
      hostHost = f hostHost;
      hostTarget = f hostTarget;
      targetTarget = f targetTarget;
    };

  renameCrossIndexFrom = prefix: x: {
    buildBuild = x."${prefix}BuildBuild";
    buildHost = x."${prefix}BuildHost";
    buildTarget = x."${prefix}BuildTarget";
    hostHost = x."${prefix}HostHost";
    hostTarget = x."${prefix}HostTarget";
    targetTarget = x."${prefix}TargetTarget";
  };

  spliceReal =
    inputs:
    let
      mash =
        # Other pkgs sets
        inputs.buildBuild
        // inputs.buildTarget
        // inputs.hostHost
        // inputs.targetTarget
        # The same pkgs sets one probably intends
        // inputs.buildHost
        // inputs.hostTarget;
      merge =
        name: defaultValue:
        let
          # `or {}` is for the non-derivation attsert splicing case, where `{}` is the identity.
          value' = mapCrossIndex (x: x.${name} or { }) inputs;

          augmentedValue = defaultValue // {
            __spliced = lib.filterAttrs (k: v: inputs.${k} ? ${name}) value';
          };
          # Get the set of outputs of a derivation. If one derivation fails to
          # evaluate we don't want to diverge the entire splice, so we fall back
          # on {}
          tryGetOutputs =
            value0:
            let
              inherit (builtins.tryEval value0) success value;
            in
            getOutputs (lib.optionalAttrs success value);
          getOutputs =
            value: lib.genAttrs (value.outputs or (lib.optional (value ? out) "out")) (output: value.${output});
          outputNames = defaultValue.outputs or (lib.optional (defaultValue ? out) "out");
          outputSplice = spliceReal (
            mapCrossIndex tryGetOutputs value' // { hostTarget = getOutputs value'.hostTarget; }
          );
        in
        # The derivation along with its outputs, which we recur
        # on to splice them together.
        if lib.isDerivation defaultValue then
          augmentedValue // lib.genAttrs outputNames (out: outputSplice.${out})
        else if lib.isAttrs defaultValue then
          spliceReal value'
        else
          # Don't be fancy about non-derivations. But we could have used used
          # `__functor__` for functions instead.
          defaultValue;
    in
    lib.mapAttrs merge mash;

  splicePackages =
    {
      pkgsBuildBuild,
      pkgsBuildHost,
      pkgsBuildTarget,
      pkgsHostHost,
      pkgsHostTarget,
      pkgsTargetTarget,
    }@args:
    if actuallySplice then spliceReal (renameCrossIndexFrom "pkgs" args) else pkgsHostTarget;

  splicedPackages =
    splicePackages {
      inherit (pkgs)
        pkgsBuildBuild
        pkgsBuildHost
        pkgsBuildTarget
        pkgsHostHost
        pkgsHostTarget
        pkgsTargetTarget
        ;
    }
    // {
      # These should never be spliced under any circumstances
      inherit (pkgs)
        pkgsBuildBuild
        pkgsBuildHost
        pkgsBuildTarget
        pkgsHostHost
        pkgsHostTarget
        pkgsTargetTarget
        buildPackages
        pkgs
        targetPackages
        ;
    };

  splicedPackagesWithXorg =
    splicedPackages
    // removeAttrs splicedPackages.xorg [
      "callPackage"
      "newScope"
      "overrideScope"
      "packages"
    ];

  packagesWithXorg =
    pkgs
    // removeAttrs pkgs.xorg [
      "callPackage"
      "newScope"
      "overrideScope"
      "packages"
    ];

  pkgsForCall = if actuallySplice then splicedPackagesWithXorg else packagesWithXorg;

in

{
  inherit splicePackages;

  # We use `callPackage' to be able to omit function arguments that can be
  # obtained `pkgs` or `buildPackages` and their `xorg` package sets. Use
  # `newScope' for sets of packages in `pkgs' (see e.g. `gnome' below).
  callPackage = pkgs.newScope { };

  callPackages = lib.callPackagesWith pkgsForCall;
  callFromScope = lib.callFromScopeWith splicedPackages;

  newScope = extra: lib.callPackageWith (pkgsForCall // extra);

  pkgs = if actuallySplice then splicedPackages // { recurseForDerivations = false; } else pkgs;

  # prefill 2 fields of the function for convenience
  makeScopeWithSplicing = lib.makeScopeWithSplicing splicePackages pkgs.newScope;
  makeScopeWithSplicing' = lib.makeScopeWithSplicing' {
    inherit splicePackages;
    inherit (pkgs) newScope;
  };

  # generate 'otherSplices' for 'makeScopeWithSplicing'
  generateSplicesForMkScope =
    attrs:
    let
      split =
        X:
        [ X ]
        ++ (
          if builtins.isList attrs then
            attrs
          else if builtins.isString attrs then
            lib.splitString "." attrs
          else
            throw "generateSplicesForMkScope must be passed a list of string or string"
        );
      bad = throw "attribute should be found";
    in
    {
      selfBuildBuild = lib.attrByPath (split "pkgsBuildBuild") bad pkgs;
      selfBuildHost = lib.attrByPath (split "pkgsBuildHost") bad pkgs;
      selfBuildTarget = lib.attrByPath (split "pkgsBuildTarget") bad pkgs;
      selfHostHost = lib.attrByPath (split "pkgsHostHost") bad pkgs;
      selfHostTarget = lib.attrByPath (split "pkgsHostTarget") bad pkgs;
      selfTargetTarget = lib.attrByPath (split "pkgsTargetTarget") { } pkgs;
    };

  # Haskell package sets need this because they reimplement their own
  # `newScope`.
  __splicedPackages =
    if actuallySplice then splicedPackages // { recurseForDerivations = false; } else pkgs;
}
