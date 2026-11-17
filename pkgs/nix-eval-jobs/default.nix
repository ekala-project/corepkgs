{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  curl,
  mimalloc,
  nixVersions,
}:

let
  # nix-eval-jobs links against the nix libraries, and its major.minor
  # tracks the nix release it was written for.
  nixComponents = nixVersions.nixComponents_2_35;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nix-eval-jobs";
  version = "2.35.4";

  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "nix-eval-jobs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-t1FbcjvTWQ1WO3hJNKN+viNXuz4BX9Pte5K4F+IJLDk=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  buildInputs = [
    curl
    mimalloc
    nixComponents.nix-store
    nixComponents.nix-fetchers
    nixComponents.nix-expr
    nixComponents.nix-flake
    nixComponents.nix-main
    nixComponents.nix-cmd
  ];

  passthru = {
    inherit nixComponents;
    nix = nixComponents.nix-cli;
  };

  meta = {
    description = "Hydra's builtin hydra-eval-jobs as a standalone";
    homepage = "https://github.com/NixOS/nix-eval-jobs";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.unix;
    mainProgram = "nix-eval-jobs";
  };
})
