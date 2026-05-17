{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # Common aliases for Node.js versions
    nodejs = "v22"; # Current LTS
    nodejs_latest = "v23";
    nodejs_22 = "v22";
    nodejs_20 = "v20";
    nodejs_18 = "v18";
  };
  defaultSelector = (p: p.v22); # Default to Node.js 22 LTS
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
