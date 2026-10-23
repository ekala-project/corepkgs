{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # Common aliases for PHP versions
    php = "v85"; # Latest stable
    php85 = "v85";
    php84 = "v84";
    php83 = "v83";
    php82 = "v82";
    php81 = "v81";
  };
  defaultSelector = (p: p.v85); # Default to PHP 8.5
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
