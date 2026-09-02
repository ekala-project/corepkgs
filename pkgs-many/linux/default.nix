{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  name = "linux";
  removed = {
    v6_17 = "2026-08-30";
  };
  defaultSelector = (p: p.v6_12);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
