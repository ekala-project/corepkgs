{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    julia_lts = "v1_10";
  };
  defaultSelector = (p: p.v1_12);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
