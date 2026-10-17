{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    pypy27 = "v2_7";
    pypy310 = "v3_10";
    pypy311 = "v3_11";
  };
  name = "pypy";
  eol = { };
  removed = { };
  defaultSelector = (p: p.v2_7);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
