{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # major.minor aliases pointing to the latest patch release
    v3_3 = "v3_3_12";
    v3_4 = "v3_4_10";
    v4_0 = "v4_0_6";
  };
  defaultSelector = (p: p.v3_4);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
