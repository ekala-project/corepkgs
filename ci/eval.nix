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
      variants = builtins.tryEval (builtins.attrValues (pkgs.${name}.variants or { }));
    in
    if variants.success then variants.value else [ ];

  # Forced through `tryEval` because an attribute that throws is not a
  # placeholder: it still has to reach `probe`, which is what decides whether
  # the throw is a package correctly refusing to evaluate or a real bug.
  isPlaceholder =
    value:
    let
      forced = builtins.tryEval value;
    in
    forced.success && forced.value == null;

  names = builtins.attrNames pkgs;
  manyVariantNames = builtins.attrNames (builtins.readDir ../pkgs-many);

  candidates = map (name: pkgs.${name}) names ++ lib.concatMap variantsOf manyVariantNames;
  targets = builtins.filter (value: !isPlaceholder value) candidates;
in
builtins.deepSeq (map probe targets) {
  evaluated = builtins.length targets;
  placeholders = builtins.length candidates - builtins.length targets;
}
