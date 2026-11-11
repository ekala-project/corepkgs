# Enumerates every package in the repository: each top-level attribute, plus
# every variant of each `pkgs-many` package, plus every derivation reachable
# through attribute sets marked with `recurseIntoAttrs` (i.e. those that set
# `recurseForDerivations = true`).
#
# `targets` also includes every package in each variant's own package set
# (`lua.v5_1.pkgs`, `python3.v3_12.pkgs`, ...); `buildable` does not.
#
# Variants live one level down (`cmake.v4`), so enumerating attribute names
# alone reaches only the default one. Their names come from the `variants`
# passthru rather than `pkgs-many/*/variants.nix`, so CI checks the same public
# package interface that users consume.
#
# Aliases are disabled. They are shims for a package already covered under its
# canonical name, so evaluating them only repeats work.
#
# When `checkMeta` is enabled, `handleEvalIssue` decides which rejections are bugs.
# `unknown-meta` and `broken-outputs` mean the `meta` itself is malformed, so
# they `abort` and name the package. Everything else -- broken, blocklisted,
# unsupported, insecure -- is a package correctly refusing to evaluate here,
# and `throw`s.
#
# What is left cannot be caught by `tryEval` and so fails the job with Nix's
# own message and source location: a missing `callPackage` argument, a missing
# attribute, or a type error. Those are the real bugs.
#
# Usage:
#   nix-instantiate --eval --strict ci/eval.nix
#   nix build --file ci/packages.nix buildable

{
  checkMeta ? false,
}:

let
  lib = import ../lib.nix { };

  pkgs = import ../. {
    config = {
      aliases.nixpkgs = false;
      inherit checkMeta;

      # Prevent non-redistributable packages from entering the binary cache.
      # Redistributable unfree packages (drivers, firmware) are fine.
      blocklistedLicenses = [
        lib.licenses.unfree
      ];

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

  # Forcing `drvPath` resolves every dependency and, for ci/eval.nix, runs
  # `check-meta`. `package` arrives unforced, so a lookup that throws is caught
  # here too.
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

  # Every package under `pkgs-many` must preserve the public `variants`
  # passthru, including packages replaced in `top-level.nix`.
  variantsOf =
    name:
    let
      variants = builtins.tryEval pkgs.${name}.variants;
    in
    if variants.success then
      variants.value
    else
      abort "${name}: pkgs-many package does not expose .variants";

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

  # Recursively collect named pairs from an attrset whose
  # `recurseForDerivations` is true, using a dotted prefix for names.
  collectRecursive =
    prefix: attrs:
    lib.concatMap (
      name:
      let
        fullName = "${prefix}.${name}";
        raw = builtins.tryEval attrs.${name};
      in
      if !raw.success then
        [ ]
      else if lib.isDerivation raw.value then
        [
          {
            name = fullName;
            value = raw.value;
          }
        ]
      else if
        builtins.isAttrs raw.value
        && (builtins.tryEval (raw.value.recurseForDerivations or false)).value or false
      then
        collectRecursive fullName raw.value
      else
        [ ]
    ) (builtins.attrNames attrs);

  names = builtins.filter (n: !builtins.elem n texliveSchemes) (builtins.attrNames pkgs);
  manyVariantNames = builtins.attrNames (builtins.readDir ../pkgs-many);

  # Build named pairs { name; value; } for top-level attrs and variants.
  # When an attribute is not a derivation but has `recurseForDerivations = true`
  # (set by `lib.recurseIntoAttrs`), recurse into it to collect the derivations
  # it contains.
  topLevel = lib.concatMap (
    name:
    let
      raw = builtins.tryEval pkgs.${name};
    in
    if !raw.success then
      [ ]
    else if lib.isDerivation raw.value then
      [
        {
          inherit name;
          value = raw.value;
        }
      ]
    else if
      builtins.isAttrs raw.value
      && (builtins.tryEval (raw.value.recurseForDerivations or false)).value or false
    then
      collectRecursive name raw.value
    else
      [
        {
          inherit name;
          value = raw.value;
        }
      ]
  ) names;

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

  # Variant package sets that are known to fail evaluation. Each entry is a
  # real bug: drop it in the PR that fixes it.
  #
  # Whole sets, as `<package>.<variant>`.
  brokenVariantSets = [
    # python/python2/mk-python-derivation.nix takes `update-python-libraries`,
    # which is not packaged.
    "pypy.pypy27"
    "pypy.v2_7"
    # Packages in the set look up `python316`, which is not defined.
    "python3.v3_16"
  ];

  # Individual packages, keyed by `<package>` (every variant) or
  # `<package>.<variant>`.
  brokenVariantPackages = {
    linux = [
      # Missing dependencies, not packaged in corepkgs.
      "ajantv2" # libajantv2
      "ax99100" # dos2unix
      "bcachefs" # bcachefs-tools
      "dpdk" # dpdk
      "mstflint_access" # mstflint
      "oci-seccomp-bpf-hook" # oci-seccomp-bpf-hook
      "sheep-net" # basiliskii
      "sysdig" # luajit
      # pkgs/linux-support/pkgs/chipsec/default.nix uses `brotli` without
      # taking it as an argument.
      "chipsec"
      # pkgs/linux-support/pkgs/zfs/generic.nix takes `linuxPackages`, which
      # the kernel package set does not provide.
      "zfs_2_3"
      "zfs_2_4"
      "zfs_unstable"
    ];
    lua = [
      # pkgs-many/lua/hooks/default.nix takes `busted` and `luarocks`, which
      # the Lua package sets do not provide.
      "bustedCheckHook"
      "luarocksCheckHook"
    ];
    perl = [
      # Invalid `meta`.
      "ImageMagick"
      # `version` is used in `src` without `finalAttrs` or `rec`.
      "IOTty"
      "IPCRun"
    ];
    # pkgs-many/nix/ components take `nix-fetchers-c`, which nix 2.28 does not
    # have.
    "nix.v2_28" = [
      "nix-everything"
      "nix-fetchers-tests"
      "nix-flake-c"
      "nix-flake-tests"
    ];
  };

  # Many variants carry their own package set (`python3.v3_12.pkgs`,
  # `lua.v5_1.pkgs`, `perl.v5_40.pkgs`, ...). Only the default variant's set is
  # reachable from the top level, and not as a set marked `recurseIntoAttrs`, so
  # without this a package that is broken against any interpreter would slip
  # through.
  variantSetPairs = lib.concatMap (
    name:
    let
      variants = variantsOf name;
    in
    lib.concatMap (
      vname:
      let
        set = builtins.tryEval (variants.${vname}.pkgs or null);
        broken = brokenVariantPackages.${name} or [ ] ++ brokenVariantPackages."${name}.${vname}" or [ ];
      in
      if builtins.elem "${name}.${vname}" brokenVariantSets then
        [ ]
      else if set.success && builtins.isAttrs set.value then
        collectRecursive "${name}.${vname}.pkgs" (builtins.removeAttrs set.value broken)
      else
        [ ]
    ) (builtins.attrNames variants)
  ) manyVariantNames;

  allPairs = topLevel ++ variantPairs;

  # Variant package sets are evaluated but not built: building every package
  # against every interpreter and kernel would multiply the CI build load.
  targets = map (pair: pair.value) (allPairs ++ variantSetPairs);
in
{
  inherit probe targets;

  # Attribute set of all buildable derivations, keyed by name.
  buildable = builtins.listToAttrs (builtins.filter (pair: isBuildable pair.value) allPairs);
}
