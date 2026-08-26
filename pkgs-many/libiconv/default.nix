{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.real);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
