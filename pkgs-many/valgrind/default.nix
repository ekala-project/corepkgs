{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.default);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
