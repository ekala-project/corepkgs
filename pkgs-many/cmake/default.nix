{ mkManyVariants }:

mkManyVariants {
  variants = ./versions.nix;
  aliases = { };
  defaultSelector = (p: p.v4);
  genericBuilder = ./package.nix;
}
