{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v1_25);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
