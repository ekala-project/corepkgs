{ mkManyVariants }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v0_20);
  genericBuilder = ./generic.nix;
}
