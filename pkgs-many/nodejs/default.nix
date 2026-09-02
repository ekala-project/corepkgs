{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # major version aliases pointing to the latest minor release
    v18 = "v18_20";
    v20 = "v20_20";
    v22 = "v22_23";
    v24 = "v24_20";
    v26 = "v26_8";
    # convenience aliases (must point to real variants, not other aliases)
    nodejs = "v24_20";
    nodejs_latest = "v26_8";
    nodejs_18 = "v18_20";
    nodejs_20 = "v20_20";
    nodejs_22 = "v22_23";
    nodejs_24 = "v24_20";
    nodejs_26 = "v26_8";
  };
  defaultSelector = (p: p.v24); # Default to Node.js 24 LTS
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
