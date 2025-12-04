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

  # This also allows for additional attrs to be passed through besides variant and src
  mkVariantArgs =
    { version, ... }@args:
    args
    // rec {
      # Some helpers commonly used to determine packaging behavior
      packageOlder = lib.versionOlder version;
      packageAtLeast = lib.versionAtLeast version;
      packageBetween = lower: higher: packageAtLeast lower && packageOlder higher;
      mkVariantPassthru =
        variantArgs: packageArgs:
        let
          variants = builtins.mapAttrs (_: v: mkPackage (variantArgs // v) packageArgs) variants';
        in
        variants // { inherit variants; };
    };

  # Re-call the generic builder with new variant args, re-wrap with makeOverridable
  # to give it the same appearance as being called by callPackage
  mkPackage = variant: lib.makeOverridable (genericExpr (mkVariantArgs (defaultVariant // variant)));
in
# The partially applied function doesn't need to be called with makeOverridable
# As callPackage will be wrapping this in makeOverridable as well
genericExpr (mkVariantArgs defaultVariant)
