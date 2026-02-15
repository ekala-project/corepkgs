{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v2_6_4);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
