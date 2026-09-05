# Evaluates every package in the repository: each top-level attribute, plus
# every variant of each `pkgs-many` package.
#
# Variants live one level down (`cmake.v4`), so enumerating attribute names
# alone reaches only the default one. Their names come from the `variants`
# passthru rather than `pkgs-many/*/variants.nix`: `top-level.nix` may replace
# an auto-called package with one that has no variants at all -- on glibc
# `libiconv` becomes a plain `runCommand` -- and only the passthru knows that.
#
# Aliases are disabled. They are shims for a package already covered under its
# canonical name, so evaluating them only repeats work.
#
# `handleEvalIssue` decides which `check-meta` rejections are bugs.
# `unknown-meta` and `broken-outputs` mean the `meta` itself is malformed, so
# they `abort` and name the package. Everything else -- broken, unfree,
# unsupported, insecure -- is a package correctly refusing to evaluate here,
# and `throw`s.
#
# What is left cannot be caught by `tryEval` and so fails the job with Nix's
# own message and source location: a missing `callPackage` argument, a missing
# attribute, or a type error. Those are the real bugs.
#
# Usage:
#   nix-instantiate --eval --strict ci/eval.nix
#   nix-build ci/packages.nix -A buildable

let
  pkgs = import ../. {
    config = {
      allowAliases = false;
      checkMeta = true;

      handleEvalIssue =
        reason: msg:
        if
          builtins.elem reason [
            "unknown-meta"
            "broken-outputs"
          ]
        then
          abort msg
        else
          throw msg;
    };
  };

  inherit (pkgs) lib;

  # Forcing `drvPath` runs `check-meta` and resolves every dependency, which is
  # the point of this job. `package` arrives unforced, so a lookup that throws
  # is caught here too.
  probe =
    package:
    let
      value = builtins.tryEval package;
    in
    builtins.tryEval (
      if value.success && lib.isDerivation value.value then
        builtins.seq value.value.drvPath null
      else
        null
    );

  # A package `top-level.nix` has replaced carries no `variants` passthru, and
  # so contributes nothing.
  variantsOf =
    name:
    let
      variants = builtins.tryEval (pkgs.${name}.variants or { });
    in
    if variants.success then variants.value else { };

  # Forced through `tryEval` because an attribute that throws is not a
  # placeholder: it still has to reach `probe`, which is what decides whether
  # the throw is a package correctly refusing to evaluate or a real bug.
  isPlaceholder =
    value:
    let
      forced = builtins.tryEval value;
    in
    value ? drvPath && forced.success && forced.value == null;

  # Check whether a value is a derivation whose drvPath can be forced.
  isBuildable =
    value:
    let
      result = builtins.tryEval (lib.isDerivation value && builtins.seq value.drvPath true);
    in
    result.success && result.value;

  # texlive scheme environments (texliveBasic … texliveFull …) are buildEnv
  # wrappers that pull in thousands of TeX packages.  Forcing drvPath on
  # them re-evaluates every inner derivation (check-meta, dependency
  # validation, etc.) even though those packages are already covered
  # individually through `texlivePackages`.  texliveFull alone accounts for
  # ~50 % of total eval time, so skip all scheme envs here.
  texliveSchemes = [
    "texliveBasic"
    "texliveBookPub"
    "texliveConTeXt"
    "texliveFull"
    "texliveGUST"
    "texliveInfraOnly"
    "texliveMedium"
    "texliveMinimal"
    "texliveSmall"
    "texliveTeTeX"
  ];

  names = builtins.filter (n: !builtins.elem n texliveSchemes) (builtins.attrNames pkgs);
  manyVariantNames = builtins.attrNames (builtins.readDir ../pkgs-many);

  # Build named pairs { name; value; } for top-level attrs and variants.
  topLevel = map (name: {
    inherit name;
    value = pkgs.${name};
  }) names;

  variantPairs = lib.concatMap (
    name:
    let
      variants = variantsOf name;
    in
    map (vname: {
      name = "${name}.${vname}";
      value = variants.${vname};
    }) (builtins.attrNames variants)
  ) manyVariantNames;

  allPairs = topLevel ++ variantPairs;

  candidatePairs = builtins.filter (
    pair:
    let
      check = builtins.tryEval (isPlaceholder pair.value);
    in
    !(check.success && check.value)
  ) allPairs;

  # For eval.nix compatibility
  candidates = map (pair: pair.value) allPairs;
  targets = map (pair: pair.value) candidatePairs;
in
{
  inherit probe targets candidates;

  # Attribute set of all buildable derivations, keyed by name.
  buildable = builtins.listToAttrs (builtins.filter (pair: isBuildable pair.value) candidatePairs);
}
