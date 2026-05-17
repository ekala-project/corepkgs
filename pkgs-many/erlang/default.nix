{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v27);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
