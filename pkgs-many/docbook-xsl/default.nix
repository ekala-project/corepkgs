{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.nons);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
