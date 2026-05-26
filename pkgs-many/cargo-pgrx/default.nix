{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v0_16_1);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
