{ packageOlder, ... }@variantArgs:

if packageOlder "7" then
  import ./v6/package.nix variantArgs
else
  import ./v7/package.nix variantArgs
