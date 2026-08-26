{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = ./aliases.nix;
  defaultSelector = (p: p.v2_34);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
