{ packageOlder, ... }@variantArgs:

if packageOlder "4" then
  import ./v3/package.nix variantArgs
else
  import ./v4/package.nix variantArgs
