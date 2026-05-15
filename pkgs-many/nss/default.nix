{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.esr);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
