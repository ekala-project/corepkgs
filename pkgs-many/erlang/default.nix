{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v28);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
