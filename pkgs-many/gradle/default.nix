{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # Common aliases for Gradle versions
    gradle_7 = "v7";
    gradle_8 = "v8";
    gradle_9 = "v9";
  };
  defaultSelector = (p: p.v8); # Default to Gradle 8
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
