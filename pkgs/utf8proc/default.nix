{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "utf8proc";
  version = "2.12.0";

  outputs = [
    "out"
    "include"
  ];
  outputInclude = "include";

  src = fetchFromGitHub {
    owner = "JuliaStrings";
    repo = "utf8proc";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+MLxHKgssEM/q4eEHYnbpNTwz/5xZ72ut6AozaLNwo0=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
    UTF8PROC_ENABLE_TESTING = false;
  };

  doCheck = false;

  meta = {
    description = "Clean C library for processing UTF-8 Unicode data";
    homepage = "https://juliastrings.github.io/utf8proc/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "utf8proc_project" finalAttrs.version;
  };
})
