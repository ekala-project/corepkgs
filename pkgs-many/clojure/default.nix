{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    clojure = "v1_12";
  };
  defaultSelector = (p: p.v1_12);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
