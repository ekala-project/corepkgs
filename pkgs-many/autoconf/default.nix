{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v2_72);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
