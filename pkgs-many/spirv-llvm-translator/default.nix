{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  # Default to v22, matching the default LLVM version
  defaultSelector = (p: p.v22);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
