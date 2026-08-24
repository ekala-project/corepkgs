{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = {
    # Common aliases for PHP versions
    php = "v84"; # Latest stable
    php84 = "v84";
    php83 = "v83";
    php82 = "v82";
    php81 = "v81";
  };
  defaultSelector = (p: p.v84); # Default to PHP 8.4
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
