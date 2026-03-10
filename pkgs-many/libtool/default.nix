{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v2_5);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
