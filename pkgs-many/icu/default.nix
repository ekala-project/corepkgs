{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v78);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
