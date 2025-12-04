{ mkManyVariants }:

mkManyVariants {
  variants = ./variants.nix;
  defaultSelector = (p: p.v1_86);
  genericBuilder = ./generic.nix;
}
