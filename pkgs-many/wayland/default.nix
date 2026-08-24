{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v1_26);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
