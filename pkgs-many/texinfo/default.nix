{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./versions.nix;
  aliases = { };
  defaultSelector = (p: p.v7);
  genericBuilder = ./package.nix;
  inherit callPackage;
}
