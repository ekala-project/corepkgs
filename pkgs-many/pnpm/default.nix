{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # major version aliases pointing to the latest minor release
    v8 = "v8_15";
    v9 = "v9_15";
    v10 = "v10_34";
    v11 = "v11_25";
    # convenience aliases (must point to real variants, not other aliases)
    pnpm = "v11_25";
    pnpm_8 = "v8_15";
    pnpm_9 = "v9_15";
    pnpm_10 = "v10_34";
    pnpm_10_29_2 = "v10_29_2";
    pnpm_11 = "v11_25";
  };
  defaultSelector = (p: p.v11); # Default to pnpm 11
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
