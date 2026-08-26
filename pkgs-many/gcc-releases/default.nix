{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v15);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
