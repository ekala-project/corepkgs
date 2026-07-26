# Enumerates all packages in the repository as a flat attribute set.
#
# Packages from pkgs-many/ have their variants flattened into the same scope:
#   cmake.v3 -> cmake_v3
#   cmake.v4 -> cmake_v4
#
# This allows tooling to build all variants, e.g.:
#   nix-build repo-packages.nix -A cmake_v4
#   nix eval .#repo-packages.x86_64-linux --apply 'builtins.attrNames'

{ system ? builtins.currentSystem }:

let
  pkgs = import ./. { inherit system; };
  inherit (pkgs) lib;

  # All multi-variant package directories
  manyVariantNames = builtins.attrNames (builtins.readDir ./pkgs-many);

  # All single packages (excluding mkManyVariants utility)
  singlePkgNames = builtins.filter (n: n != "mkManyVariants") (
    builtins.attrNames (builtins.readDir ./pkgs)
  );

  # Determine variant names from the filesystem by importing the variants/versions file.
  # This is evaluated purely from file data, no package building required.
  variantNamesFor =
    name:
    let
      dir = ./pkgs-many + "/${name}";
      versionsFile = dir + "/versions.nix";
      variantsFile = dir + "/variants.nix";
      raw =
        if builtins.pathExists versionsFile then
          import versionsFile
        else
          import variantsFile;
      # Handle the case where variants.nix uses a let-in block (returns an attrset)
      # or is a function (needs to be called — but we just need the names from file-based ones)
    in
    if builtins.isAttrs raw then
      builtins.attrNames raw
    else
      # If it's a function (e.g. takes buildPackages), fall back to reading from the built package
      builtins.attrNames (pkgs.${name}.variants or { });

  # For a given multi-variant package, flatten its variants into prefixed attributes.
  # e.g. "cmake" with variants {v3, v4, minimal, curses} becomes:
  #   { cmake_v3 = ...; cmake_v4 = ...; cmake_minimal = ...; cmake_curses = ...; }
  flattenVariants =
    name:
    let
      varNames = variantNamesFor name;
    in
    # Include the default package under its own name
    { ${name} = pkgs.${name}; }
    // lib.genAttrs
      (map (vname: "${name}_${vname}") varNames)
      (flatName:
        let
          vname = lib.removePrefix "${name}_" flatName;
        in
        pkgs.${name}.${vname}
      );

  # Single packages: reference them lazily from pkgs by name.
  # Values are only evaluated when accessed.
  singlePackages = lib.genAttrs singlePkgNames (name: pkgs.${name});

  # Multi-variant packages: flatten all variants
  manyVariantPackages = lib.foldl' (acc: name: acc // flattenVariants name) { } manyVariantNames;

in
singlePackages // manyVariantPackages
