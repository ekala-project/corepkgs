{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vulkan-headers";
  version = "1.4.369";

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    ninja
  ];

  cmakeEntries = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    VULKAN_HEADERS_ENABLE_MODULE = "OFF";
  };

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Headers";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TovDv0Aj7HI5FtTFfGuLmjlMt79djZsuyKpGG2lsaoU=";
  };

  meta = {
    description = "Vulkan Header files and API registry";
    homepage = "https://www.lunarg.com";
    platforms = lib.platforms.unix;
    license = lib.licenses.asl20;
  };
})
