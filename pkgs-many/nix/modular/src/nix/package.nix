{
  lib,
  mkMesonExecutable,

  nix-store,
  nix-expr,
  nix-main,
  nix-cmd,

  # Configuration Options

  version,
}:

mkMesonExecutable (finalAttrs: {
  pname = "nix";
  inherit version;

  workDir = ./.;

  buildInputs = [
    nix-store
    nix-expr
    nix-main
    nix-cmd
  ];

  mesonEntries = {
    ${if lib.versionAtLeast version "2.35" then "mimalloc" else null} = "disabled";
  };

  meta = {
    mainProgram = "nix";
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };

})
