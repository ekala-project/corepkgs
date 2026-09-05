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
  inherit (lib.customisation) mapCrossIndex renameCrossIndexFrom;
  inherit (lib) mapAttrs;

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
          # Splice passthru attributes of derivations so that sub-attributes
          # (e.g. cmake.minimal) also carry __spliced and resolve correctly
          # when used in nativeBuildInputs during cross-compilation.
          passthruNames = builtins.filter (
            n:
            !builtins.elem n (
              outputNames
              ++ [
                "__spliced"
                "type"
                "drvPath"
                "outPath"
                "drvAttrs"
                "outputName"
                "all"
                "outputs"
                "override"
                "overrideAttrs"
                "overrideDerivation"
              ]
            )
          ) (builtins.attrNames defaultValue);
          # Only splice passthru attrs that are derivations — recursing into
          # arbitrary attrsets (e.g. stdenv internals) causes infinite recursion.
          passthruSplice = lib.genAttrs passthruNames (
            pname:
            let
              pvalue = defaultValue.${pname};
              pvalue' = mapCrossIndex (x: x.${name}.${pname} or { }) inputs;
            in
            if lib.isDerivation pvalue then
              let
                pAugmented = pvalue // {
                  __spliced = lib.filterAttrs (_: v: v != { }) pvalue';
                };
              in
              pAugmented
            else
              pvalue
          );
        in
        # The derivation along with its outputs, which we recur
        # on to splice them together.
        if lib.isDerivation defaultValue then
          augmentedValue // passthruSplice // lib.genAttrs outputNames (out: outputSplice.${out})
        else if lib.isAttrs defaultValue then
          spliceReal value'
        else
          # Don't be fancy about non-derivations. But we could have used used
          # `__functor__` for functions instead.
          defaultValue;
    in
    mapAttrs merge mash;

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

  # Flatten the xorg backward-compatibility aliases (`libXau`, `libXext`, ...)
  # into the `callPackage` resolution scope, so a package still asking for a
  # legacy CamelCase name gets one. The `xorg` set holds only aliases to
  # top-level packages, so this adds names, never new packages.
  #
  # TODO(corepkgs): drop this once no package asks for a CamelCase xorg name.
  # Upstream has no equivalent -- there `pkgsForCall` is `splicedPackages`/`pkgs`
  # directly -- so every argument resolved through this flattening belongs to a
  # package that has not been renamed yet. 14 such names are still requested,
  # by mesa, xvfb, libepoxy, texlive, gdk-pixbuf, conky, nvidia-x11, java,
  # vulkan-loader and xp-pen-drivers.
  #
  # Removing it before then does not fail loudly everywhere: an argument with a
  # default silently takes it instead. `vulkan-loader` has `libXrandr ? null`
  # guarding `enableX11`, so it would keep evaluating and quietly lose X11.
  splicedPackagesWithXorg = splicedPackages // (splicedPackages.xorg or { });

  packagesWithXorg = pkgs // (pkgs.xorg or { });

  pkgsForCall = if actuallySplice then splicedPackagesWithXorg else packagesWithXorg;

in

{
  inherit splicePackages;

  # We use `callPackage' to be able to omit function arguments that can be
  # obtained from `pkgs` or `buildPackages`.
  # Use `newScope' for sets of packages in `pkgs' (see e.g. `gnome' below).
  callPackage = pkgs.newScope { };

  callPackages = lib.callPackagesWith pkgsForCall;
  callFromScope = lib.callFromScopeWith splicedPackages;

  newScope = extra: lib.callPackageWith (pkgsForCall // extra);

  pkgs = if actuallySplice then splicedPackages // { recurseForDerivations = false; } else pkgs;

  # mkEkaPackage — scope-based dependency declaration (EEP 0041)
  mkEkaPackage = {
    inherit (pkgs) stdenv;
    cc = pkgs.stdenv.cc;
    scopes = {
      buildBuild = pkgs.pkgsBuildBuild;
      buildHost = pkgs.pkgsBuildHost;
      buildTarget = pkgs.pkgsBuildTarget;
      hostHost = pkgs.pkgsHostHost;
      hostTarget = pkgs.pkgsHostTarget;
      targetTarget = pkgs.pkgsTargetTarget;
    };

    __functor =
      self: fnOrAttrs:
      (import ./generic/make-eka-package.nix {
        inherit lib;
        inherit (pkgs) config;
        inherit (self) stdenv cc scopes;
      }).mkEkaPackage
        fnOrAttrs;
  };

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
