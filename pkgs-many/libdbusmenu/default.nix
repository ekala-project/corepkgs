{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.base);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
