{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v3_02);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
