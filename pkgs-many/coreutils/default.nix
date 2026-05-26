{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.minimal);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
