{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  # Use binary GHC for now until we have Haskell package infrastructure
  # to build hadrian and its dependencies
  defaultSelector = (p: p.v9_8_4_binary);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
