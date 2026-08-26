{
  lib,
  mkMesonLibrary,

  nix-util-test-support,
  nix-store,
  nix-store-c,

  gtest,
  rapidcheck,

  # Configuration Options

  version,
}:

mkMesonLibrary (finalAttrs: {
  pname = "nix-store-test-support";
  inherit version;

  workDir = ./.;

  propagatedBuildInputs = [
    nix-util-test-support
    nix-store
    nix-store-c
    rapidcheck
  ]
  ++ lib.optional (lib.versionAtLeast version "2.34") gtest;

  mesonFlags = [
  ];

  meta = {
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };

})
