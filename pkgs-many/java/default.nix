{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v21); # Default to Java 21 LTS
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
