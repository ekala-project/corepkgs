{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "upx";
  version = "5.2.0";

  src = fetchFromGitHub {
    owner = "upx";
    repo = "upx";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-6LTDz4gMak0V7KiZOeuQgm+RubKRp3zhF6T6SZzZ5Dk=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  meta = {
    homepage = "https://upx.github.io/";
    description = "Ultimate Packer for eXecutables";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
    mainProgram = "upx";
  };
})
