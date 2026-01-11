{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v3_0);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
