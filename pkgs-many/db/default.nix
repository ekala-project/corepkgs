{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v5_3);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
