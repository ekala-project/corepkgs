{
  lib,
  config,

  # Allow for alias and variant exprs to reference things from pkgs
  callFromScope,
}:

{
  # Intended to be an attrset of { "<exposed variant>" = { variant = "<full variant>"; src = <path>; } }
  # or a file containing such variant information
  # Type: AttrSet AttrSet
  variants,

  # Similar to variants, but instead contain deprecation and removal messages
  # Only added when `config.allowAliases` is true
  # This is passed the variants attr set to allow for directly referencing the variant entries
  # Type: AttrSet AttrSet -> AttrSet AttrSet.
  aliases ? { ... }: { },

  # Package name used in EOL/removed messages (e.g. "linux")
  # Type: String
  name ? null,

  # Variants that have reached end-of-life. Still buildable but emit a warning.
  # Maps variant name to EOL date string, e.g. { v6_17 = "2026-08-01"; }
  # Requires `name` to be set.
  # Type: AttrSet String
  eol ? { },

  # Variants that have been fully removed. Accessing them throws an error.
  # Maps variant name to removal date string, e.g. { v6_13 = "2026-02-01"; }
  # Only honoured when `config.allowAliases` is true.
  # Requires `name` to be set.
  # Type: AttrSet String
  removed ? { },

  # A "projection" from the variant set to a variant to be used as the default
  # Type: AttrSet package -> package
  defaultSelector,

  # Nix expression which takes variant and package args, and returns an attrset to pass to mkDerivation
  # Type: AttrSet -> AttrSet -> AttrSet
  genericBuilder,

  # This allows for each variant to be called with different inputs
  callPackage,
}:

# Some assertions as poor man's type checking
assert builtins.isFunction defaultSelector;
assert eol != { } -> name != null;
assert removed != { } -> name != null;

let
  importIfPath = x: if builtins.isPath x then import x else x;
  callIfFunction = x: if builtins.isFunction x then callFromScope x { } else x;

  variantsRaw = callIfFunction (importIfPath variants);
  aliasesExpr = importIfPath aliases;
  # Do not use callFromScope as the genericExpr should get called from package scope later
  genericExpr = importIfPath genericBuilder;

  aliasesRaw =
    if builtins.isFunction aliasesExpr then
      aliasesExpr {
        inherit lib;
        variants = variantsRaw;
      }
    else
      aliasesExpr;

  # Core variant-building logic, parameterized on the raw variant set.
  # This allows extendVariants to re-derive everything with additional variants.
  mkSet =
    rawVariants:
    let
      # Resolve string aliases against the current raw variants
      aliases' = builtins.mapAttrs (_: v: if builtins.isString v then rawVariants.${v} else v) aliasesRaw;

      currentVariants = rawVariants // aliases';

      defaultVariant = defaultSelector currentVariants;

      # Removed variants: throw on access (only when config.allowAliases)
      removedOverlay = lib.optionalAttrs config.allowAliases (
        builtins.mapAttrs (
          n: date: throw "${name}.${n} is no longer available and was removed on ${date}."
        ) removed
      );

      mkVariantPassthru =
        variantArgs:
        let
          vs = builtins.mapAttrs (_: v: mkPackage (variantArgs // v)) currentVariants;
          # EOL variants: wrap built packages with lib.warn
          eolWrapped = builtins.mapAttrs (
            n: date:
            lib.warn "${name}.${n} is EOL as of ${date}. It is recommended to use a newer version." vs.${n}
          ) eol;
        in
        vs // eolWrapped // removedOverlay // { variants = vs; };

      # This also allows for additional attrs to be passed through besides variant and src
      mkVariantArgs =
        { version, ... }@args:
        args
        // rec {
          # Some helpers commonly used to determine packaging behavior
          packageOlder = lib.versionOlder version;
          packageAtLeast = lib.versionAtLeast version;
          packageBetween = lower: higher: packageAtLeast lower && packageOlder higher;
          # For variants to compose, the package expressions must do `passthru = mkVariantPassthru variantArgs`
          # This allows for built variant args to be remembered, trying to do this construction
          # before getting callPackage'd leads to infinite recursion as it's not lazy
          inherit mkVariantPassthru;
        };

      # Re-call the generic builder with new variant args, re-wrap with makeOverridable
      # to give it the same appearance as being called by callPackage
      mkPackage =
        variant:
        let
          variantArgs = mkVariantArgs (defaultVariant // variant);
          pkg = callPackage (genericExpr variantArgs) { };
        in
        pkg.overrideAttrs (o: {
          passthru =
            o.passthru or { }
            // mkVariantPassthru variantArgs
            // {
              inherit variantArgs;
              extendVariants = extendVariantsFn rawVariants;
            };
        });

    in
    {
      inherit mkVariantPassthru currentVariants;
    };

  # Extend the variant set with additional variant definitions.
  # Returns the default package of the extended set (with all variants in passthru).
  extendVariantsFn =
    baseRawVariants: extraVariants:
    let
      extended = mkSet (baseRawVariants // extraVariants);
    in
    defaultSelector (extended.mkVariantPassthru extended.currentVariants);

  topSet = mkSet variantsRaw;
  defaultPackage = defaultSelector (topSet.mkVariantPassthru topSet.currentVariants);
in
# The calling scope will apply `callPackage`, so we need to return the partially
# applied function
defaultPackage.override
