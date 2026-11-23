{
  lib,
  pkgs,
  fetchFromGitHub,
  buildPythonPackage,
  rustPlatform,
  callPackage,
}:

buildPythonPackage (finalAttrs: {
  pname = "uv-build";
  version = "0.13.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    tag = finalAttrs.version;
    hash = "sha256-D+NUKgwVCfsc8t4egZ7Tq8pjqHm0vYlJbqnH7D1I0ZU=";
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-nmUByTBYI4dzj+ohszZ3x8jOb5yacMInAPnP5Fn2zOA=";
  };

  buildAndTestSubdir = "crates/uv-build";

  # $src/.github/workflows/build-binaries.yml#L139
  maturinBuildProfile = "minimal-size";

  pythonImportsCheck = [ "uv_build" ];

  # Run the tests of a package built by `uv_build`.
  passthru = {
    tests.built-by-uv = callPackage ./built-by-uv.nix { inherit (pkgs) uv; };

    # updateScript is not needed here, as updating is done on staging
  };

  meta = {
    description = "Minimal build backend for uv";
    homepage = "https://docs.astral.sh/uv/reference/settings/#build-backend";
    inherit (pkgs.uv.meta) changelog license;
    platforms = lib.platforms.unix;
  };
})
