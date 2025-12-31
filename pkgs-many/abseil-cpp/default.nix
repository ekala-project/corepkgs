{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v202508);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
