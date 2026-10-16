{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v12);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
