{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    r = "v4_4";
    rLang = "v4_4";
  };
  defaultSelector = (p: p.v4_4);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
