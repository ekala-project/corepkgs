{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v0_21);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
