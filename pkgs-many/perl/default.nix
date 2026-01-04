{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v5_40);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
