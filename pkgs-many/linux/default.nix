{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v6_12);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
