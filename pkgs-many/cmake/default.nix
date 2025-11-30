{ mkManyVariants }:

mkManyVariants {
  versions = ./versions.nix;
  aliases = { };
  defaultSelector = (p: p.v3);
  genericBuilder = ./package.nix;
}
