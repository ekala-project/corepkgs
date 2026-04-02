{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  # Default to v21 (LLVM 21.1.2)
  defaultSelector = (p: p.v21);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
