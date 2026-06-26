# Nix-specific fixes: hardcoded paths, test sandbox issues, etc.
# Build up incrementally as packages are added.
{ pkgs, haskellLib }:

with haskellLib;

self: super: {
  # Add Nix-specific overrides here as needed.
}
