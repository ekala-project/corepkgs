{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  name = "python3";
  eol = { };
  removed = { };
  defaultSelector = (p: p.v3_13);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
