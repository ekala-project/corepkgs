{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v3_5);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
