{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    nim = "v2_2";
    nimble = "v2_2";
  };
  defaultSelector = (p: p.v2_2);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
