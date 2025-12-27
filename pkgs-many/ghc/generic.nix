{
  version,
  sha256 ? null,
  rev ? null,
  isBinary ? false,
  useMake ? false,
  packageAtLeast,
  packageOlder,
  mkVariantPassthru,
  ...
}@variantArgs:

# For binary versions, we import the complete binary package file directly
if isBinary then
  import ./${version}.nix variantArgs

# For GHC 9.4.x and older, use the Make-based build system
else if useMake then
  import ./common-make-native-bignum.nix {
    inherit version sha256;
  }

# For modern GHC (9.6+), use the Hadrian build system
else
  import ./common-hadrian.nix variantArgs
