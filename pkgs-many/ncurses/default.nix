{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v6);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
