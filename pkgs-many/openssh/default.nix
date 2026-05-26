{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  defaultSelector = (p: p.openssh);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
