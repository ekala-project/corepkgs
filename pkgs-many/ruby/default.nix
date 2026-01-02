{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  defaultSelector = (p: p.v3_3);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
