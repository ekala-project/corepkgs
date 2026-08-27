# Evaluates every top-level attribute of the package set.
#
# Aliases are disabled. They are compatibility shims that resolve to a package
# already covered under its canonical name, so evaluating them only repeats
# work -- and a shim for something this repo does not package should not make
# the job fail.
#
# `handleEvalIssue` decides which `check-meta` rejections are bugs:
#
#   * `unknown-meta` and `broken-outputs` mean the `meta` itself is malformed,
#     which is always a mistake, so they `abort` and name the package.
#   * Everything else -- broken, unfree, unsupported, insecure -- is a package
#     correctly refusing to evaluate here. Those `throw`, and are ignored.
#
# What is left cannot be caught by `tryEval` and so fails the job with Nix's
# own message and source location: a missing `callPackage` argument (an
# `abort`), a missing attribute, or a type error. Those are the real bugs.
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

  # Forcing `drvPath` runs `check-meta` and resolves every dependency of the
  # package, which is the point of this job.
  probe =
    name:
    let
      value = builtins.tryEval pkgs.${name};
    in
    builtins.tryEval (
      if value.success && lib.isDerivation value.value then
        builtins.seq value.value.drvPath null
      else
        null
    );

  names = builtins.attrNames pkgs;
in
builtins.deepSeq (map probe names) (builtins.length names)
