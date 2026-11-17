{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  pkg-config,
  zstd,
  gitMinimal,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "iets";
  # Pinned to the revision ekapkgs-cli and eka-ci are developed against.
  version = "0.2.0-unstable-2026-11-06";

  src = fetchFromGitHub {
    owner = "numtide";
    repo = "iets";
    rev = "5e9589e7570bfdf7997e5583d08533f0b95b5393";
    # The test and fuzz corpora contain real store paths, which a
    # fixed-output derivation may not reference.
    postFetch = ''
      rm -r $out/{tests,fuzz,bench,examples}
    '';
    hash = "sha256-j9Re/ZYcugYTd6bOzdJKg/qJVdLErNxSOw3r2Cp/gjY=";
  };

  cargoHash = "sha256-EM2mV/cs9Isr8bgbe6QKgkDiYYmBLY9MyI8NWza/B2I=";

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [ zstd ];

  # Link the system zstd rather than building zstd-sys' bundled copy.
  env = {
    ZSTD_SYS_USE_PKG_CONFIG = "1";
    IETS_FALLBACK_PATH = lib.makeBinPath [ gitMinimal ];
  };

  postInstall = ''
    installShellCompletion \
      --bash src/cli/complete/iets.bash \
      --zsh src/cli/complete/iets.zsh \
      --fish src/cli/complete/iets.fish
  '';

  meta = {
    description = "Fast Nix evaluator and remote-build client";
    homepage = "https://github.com/numtide/iets";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
    mainProgram = "iets";
  };
})
