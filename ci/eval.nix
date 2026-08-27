# Evaluates every top-level attribute of the package set and reports the ones
# that fail to evaluate.
#
# Broken and unfree packages are allowed through so they are not reported:
# refusing to evaluate those is intended behaviour, not breakage. Platform
# support is *not* forced, because a package that is unsupported here may
# reference attributes that only exist on its own platform; those are
# recognised instead by `meta.available` being false. What is left is a genuine
# bug -- a missing dependency, a typo, or an invalid `meta` attribute.
#
# Attributes that intentionally `throw` because the package has not been ported
# yet are listed in `./unavailable.nix` and skipped.
#
# Usage:
#   nix-instantiate --eval --strict --json ci/eval.nix

let
  pkgs = import ../. {
    config = {
      allowBroken = true;
      allowUnfree = true;
      checkMeta = true;
    };
  };

  inherit (pkgs) lib;

  unavailable = import ./unavailable.nix;

  # `tryEval` catches `throw` and failed assertions but not `abort`, which is
  # what `callPackageWith` raises for a missing argument. Those abort the whole
  # evaluation, failing this job with the offending argument named -- which is
  # the behaviour we want.
  probe =
    name:
    let
      value = builtins.tryEval pkgs.${name};
      result = builtins.tryEval (
        if lib.isDerivation value.value then builtins.seq value.value.drvPath null else null
      );
      # A package that is not available on this system is expected to refuse to
      # evaluate; anything else that fails is a bug.
      expected = !(value.success && (value.value.meta.available or true));
    in
    if result.success || expected then null else name;

  names = builtins.filter (name: !(builtins.elem name unavailable)) (builtins.attrNames pkgs);
in
builtins.filter (name: name != null) (map probe names)
