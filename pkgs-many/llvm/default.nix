{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  # Default to v22 (LLVM 22.1.4)
  defaultSelector = (p: p.v22);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
