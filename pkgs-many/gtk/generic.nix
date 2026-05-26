{ majorVersion, ... }@variantArgs:

if majorVersion == 2 then
  import ./generic-v2.nix variantArgs
else if majorVersion == 3 then
  import ./generic-v3.nix variantArgs
else if majorVersion == 4 then
  import ./generic-v4.nix variantArgs
else
  throw "gtk: unsupported majorVersion ${toString majorVersion}"
