{ majorVersion, ... }@variantArgs:

if majorVersion == 7 then
  import ./generic-v7.nix variantArgs
else if majorVersion == 6 then
  import ./generic-v6.nix variantArgs
else
  throw "imagemagick: unsupported majorVersion ${toString majorVersion}"
