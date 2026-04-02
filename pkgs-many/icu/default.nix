{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.icu78);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
