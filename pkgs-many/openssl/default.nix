{ mkManyVariants }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.v3_6);
  genericBuilder = ./generic.nix;
}
