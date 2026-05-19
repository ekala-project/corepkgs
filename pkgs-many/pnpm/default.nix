{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # Common aliases for pnpm versions
    pnpm = "v11"; # Latest stable
    pnpm_11 = "v11";
    pnpm_10 = "v10";
    pnpm_10_29_2 = "v10_29_2";
    pnpm_9 = "v9";
    pnpm_8 = "v8";
  };
  defaultSelector = (p: p.v11); # Default to pnpm 11
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
