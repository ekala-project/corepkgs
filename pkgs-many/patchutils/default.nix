{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v0_3_4);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
