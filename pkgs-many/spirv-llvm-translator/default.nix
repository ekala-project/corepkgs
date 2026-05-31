{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  # Default to v21, matching the default LLVM version
  defaultSelector = (p: p.v21);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
