{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v2_73);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
