{ mkManyVariants }:

mkManyVariants {
  variants = ./versions.nix;
  aliases = { };
  defaultSelector = (p: p.v3);
  genericBuilder = ./package.nix;
}
