# Haskell programming language module (GHC)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };

  # GHC uses unusual variant names like v9_0_2_binary, v9_8_4_binary
  resolveGhcVersion =
    pkgs': version:
    let
      stripped = builtins.replaceStrings [ "." ] [ "_" ] version;
      variantName = "v${stripped}_binary";
      variant = pkgs'.ghc.${variantName} or null;
    in
    if variant != null then
      variant
    else
      let
        availableNames = builtins.filter (n: builtins.match "v[0-9_]+_binary" n != null) (
          builtins.attrNames pkgs'.ghc
        );
      in
      throw "languages.haskell: version \"${version}\" is not available. Known variants: ${lib.concatStringsSep ", " availableNames}";

  mod = langLib.mkLanguageModule {
    name = "haskell";
    defaultPackage = pkgs: pkgs.ghc;
    resolveVersion = resolveGhcVersion;
    environmentVariables = _: {
      CABAL_DIR = "$HOME/.cabal";
    };
    sessionPath = _: [ "$HOME/.cabal/bin" ];
  };
in

mod { inherit config lib pkgs; }
