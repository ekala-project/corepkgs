{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "spirv-headers";
  version = "2026.08.0";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HvdKHnraSSWBriVgiNfhnC60moYRseDb3aRxxoANX1I=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  meta = {
    description = "Machine-readable components of the Khronos SPIR-V Registry";
    homepage = "https://github.com/KhronosGroup/SPIRV-Headers";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
