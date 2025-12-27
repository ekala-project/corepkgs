{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v1_0);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
