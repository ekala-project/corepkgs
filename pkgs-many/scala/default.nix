{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    scala = "v3_6";
    scala_3 = "v3_6";
    scala_2_13 = "v2_13";
  };
  defaultSelector = (p: p.v3_6);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
