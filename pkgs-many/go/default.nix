{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # major.minor aliases pointing to the latest patch release
    v1_24 = "v1_24_13";
    v1_25 = "v1_25_14";
    v1_26 = "v1_26_8";
  };
  defaultSelector = (p: p.v1_25);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
