{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  name = "wlroots";
  removed = {
    v0_17 = "2025-03-25";
  };
  defaultSelector = (p: p.v0_19);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
