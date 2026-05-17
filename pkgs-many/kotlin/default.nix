{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    kotlin = "v2_1";
    kotlinc = "v2_1";
  };
  defaultSelector = (p: p.v2_1);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
