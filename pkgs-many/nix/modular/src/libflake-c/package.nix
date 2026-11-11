{
  lib,
  mkMesonLibrary,

  nix-store-c,
  nix-expr-c,
  # Only exists from 2.29; every use below is gated on that version.
  nix-fetchers-c ? null,
  nix-flake,

  # Configuration Options

  version,
}:

mkMesonLibrary (finalAttrs: {
  pname = "nix-flake-c";
  inherit version;

  workDir = ./.;

  propagatedBuildInputs = [
    nix-expr-c
    nix-store-c
  ]
  ++ lib.optionals (lib.versionAtLeast version "2.29pre") [
    nix-fetchers-c
  ]
  ++ [
    nix-flake
  ];

  mesonEntries = { };

  meta = {
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };

})
