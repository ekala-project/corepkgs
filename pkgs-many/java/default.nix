{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v25); # Default to Java 25 LTS
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
