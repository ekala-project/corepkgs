{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  # Default to lua5_4 (Lua 5.4.7)
  defaultSelector = (p: p.v5_4);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
