{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v1_98);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
