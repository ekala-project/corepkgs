{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v2_15);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
