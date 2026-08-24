{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    r = "v4_6";
    rLang = "v4_6";
  };
  defaultSelector = (p: p.v4_6);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
