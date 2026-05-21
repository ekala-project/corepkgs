# Script to generate a frozen release overlay from pkgs-many/ packages
#
# Usage:
#   nix-build scripts/freeze-release.nix --argstr releaseName "stable-2026.1" --argstr outputPath "./overlays/frozen-2026.1.nix"
#
# This script:
# 1. Enumerates all packages in pkgs-many/
# 2. Reads each package's default.nix to find the default variant
# 3. Generates an overlay that pins each package to its default variant

{
  releaseName ? "stable-unknown",
  outputPath ? "./overlays/frozen-release.nix",
  corePkgsPath ? ./..,
  gitCommit ? "unknown",
  timestamp ? "unknown",
}:

let
  pkgs = import corePkgsPath { };
  lib = pkgs.lib;

  # List all packages in pkgs-many/
  pkgsManyPath = corePkgsPath + "/pkgs-many";
  pkgsManyPackages = builtins.attrNames (builtins.readDir pkgsManyPath);

  # Parse a default.nix file to extract the defaultSelector pattern
  # This is a heuristic approach that looks for common patterns like:
  # - defaultSelector = (p: p.v22);
  # - defaultSelector = (p: p.v1_26);
  parseDefaultSelector =
    pkgName:
    let
      defaultNixPath = pkgsManyPath + "/${pkgName}/default.nix";
      variantsNixPath = pkgsManyPath + "/${pkgName}/variants.nix";
    in
    if !builtins.pathExists defaultNixPath || !builtins.pathExists variantsNixPath then
      null
    else
      let
        # Load the default.nix
        defaultNixContent = builtins.readFile defaultNixPath;

        # Try to extract the default selector pattern using regex
        # Looking for patterns like: defaultSelector = (p: p.vXX);
        # This is a simple heuristic - we extract what comes after "p.p."
        lines = lib.splitString "\n" defaultNixContent;

        # Find line containing defaultSelector
        selectorLines = builtins.filter (line: builtins.match ".*defaultSelector.*" line != null) lines;

        # Extract variant name from the selector
        extractVariant =
          line:
          let
            # Try to match patterns like: defaultSelector = (p: p.v22);
            # or: defaultSelector = p: p.v1_26;
            match1 = builtins.match ".*p\\.([a-zA-Z0-9_]+).*" line;
          in
          if match1 != null then builtins.head match1 else null;

        variantName = if selectorLines != [ ] then extractVariant (builtins.head selectorLines) else null;

        # Load variants to verify the variant exists
        variants = import variantsNixPath;
        variantExists = variantName != null && variants ? ${variantName};
      in
      if variantExists then variantName else null;

  # Build a map of package name -> default variant name
  packageVariantMap = builtins.listToAttrs (
    builtins.filter (x: x.value != null) (
      map (pkgName: {
        name = pkgName;
        value = parseDefaultSelector pkgName;
      }) pkgsManyPackages
    )
  );

  # Generate the overlay content
  overlayHeader = ''
    # Frozen Release: ${releaseName}
    # Generated: ${timestamp}
    # From commit: ${gitCommit}
    #
    # This overlay freezes all pkgs-many/ packages to their default variants
    # to create a stable release where major versions don't change over time.
    #
    # Usage:
    #   import ./. { overlays = [ (import ${outputPath}) ]; }
    #   # Or in your configuration:
    #   nixpkgs.overlays = [ (import ${outputPath}) ];

  '';

  overlayBody =
    let
      entries = lib.mapAttrsToList (
        pkgName: variantName: "  ${pkgName} = prev.${pkgName}.${variantName};"
      ) packageVariantMap;
      sortedEntries = lib.sort (a: b: a < b) entries;
    in
    ''
      final: prev: {
      ${lib.concatStringsSep "\n" sortedEntries}
      }
    '';

  overlayContent = overlayHeader + overlayBody;

  # Write the overlay to a file
  result = pkgs.writeTextFile {
    name = "frozen-release-overlay";
    text = overlayContent;
    destination = "/" + baseNameOf outputPath;
  };

in
result
