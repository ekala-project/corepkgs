{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nix-update-script,
  testers,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "llhttp";
  version = "9.4.3";

  src = fetchFromGitHub {
    owner = "nodejs";
    repo = "llhttp";
    tag = "release/v${finalAttrs.version}";
    hash = "sha256-wz87FgdZn0vtdlTWOZL5/Ujhs/uzSwFMHzQ6D9S7dH8=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    (lib.cmakeBool "BUILD_STATIC_LIBS" stdenv.hostPlatform.isStatic)
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version-regex=release/v(.+)" ];
  };
  passthru.tests = {
    inherit (python3.pkgs) aiohttp;

    pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
      moduleNames = [ "libllhttp" ];
    };
  };

  meta = {
    description = "Port of http_parser to llparse";
    homepage = "https://llhttp.org/";
    changelog = "https://github.com/nodejs/llhttp/releases/tag/release/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
