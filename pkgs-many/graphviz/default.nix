{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.withoutXorg);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
