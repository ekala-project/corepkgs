{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v4_1);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
