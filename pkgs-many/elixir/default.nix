{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    elixir = "v1_18";
    elixir_1_18 = "v1_18";
    elixir_1_17 = "v1_17";
  };
  defaultSelector = (p: p.v1_18);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
