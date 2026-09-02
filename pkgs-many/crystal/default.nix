{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v1_21);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
