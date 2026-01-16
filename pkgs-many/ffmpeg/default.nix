{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  defaultSelector = (p: p.v8);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
