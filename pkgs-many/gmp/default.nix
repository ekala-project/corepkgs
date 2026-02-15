{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v6_3);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
