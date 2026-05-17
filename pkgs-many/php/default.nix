{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # Common aliases for PHP versions
    php = "v83"; # Latest stable
    php84 = "v84";
    php83 = "v83";
    php82 = "v82";
    php81 = "v81";
  };
  defaultSelector = (p: p.v83); # Default to PHP 8.3
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
