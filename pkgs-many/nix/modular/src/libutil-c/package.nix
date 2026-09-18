{
  lib,
  mkMesonLibrary,

  nix-util,

  # Configuration Options

  version,
}:

mkMesonLibrary (finalAttrs: {
  pname = "nix-util-c";
  inherit version;

  workDir = ./.;

  propagatedBuildInputs = [
    nix-util
  ];

  mesonEntries = { };

  meta = {
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };

})
