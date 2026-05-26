{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.full);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
