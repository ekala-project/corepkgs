# Per-package fixes shared across all GHC versions.
# Build up incrementally as packages are added.
{ pkgs, haskellLib }:

with haskellLib;

self: super: {
  # Add package-specific overrides here as needed.
  # Example:
  #   some-package = dontCheck super.some-package;
}
