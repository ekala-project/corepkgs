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
  packages = import ./packages.nix;
  inherit (packages) probe targets candidates;
in
builtins.deepSeq (map probe targets) {
  evaluated = builtins.length targets;
  placeholders = builtins.length candidates - builtins.length targets;
}
