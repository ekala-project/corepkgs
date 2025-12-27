{ lib, config }:

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

let
  variantsRaw = if builtins.isPath variants then import variants else variants;
  aliasesExpr = if builtins.isPath aliases then import aliases else aliases;
  genericExpr = if builtins.isPath genericBuilder then import genericBuilder else genericBuilder;

  aliases' =
    if builtins.isFunction aliasesExpr then
      aliasesExpr {
        inherit lib;
        variants = variantsRaw;
      }
    else
      aliasesExpr;
  variants' =
    if config.allowAliases then
      # Not sure if aliases or variants should have priority
      variantsRaw // aliases'
    else
      variantsRaw;

  defaultVariant = defaultSelector variants';

  mkVariantPassthru =
    variantArgs:
    let
      variants = builtins.mapAttrs (_: v: mkPackage (variantArgs // v)) variants';
    in
    variants // { inherit variants; };

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
        };
    });

  defaultPackage = defaultSelector (mkVariantPassthru variants');
in
# The calling scope will apply `callPackage`, so we need to return the partially
# applied function
defaultPackage.override
