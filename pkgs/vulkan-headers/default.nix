{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vulkan-headers";
  version = "1.4.341.0";

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    ninja
  ];

  cmakeFlags = lib.optionals stdenv.hostPlatform.isDarwin [ "-DVULKAN_HEADERS_ENABLE_MODULE=OFF" ];

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Headers";
    rev = "vulkan-sdk-${finalAttrs.version}";
    hash = "sha256-R/t0mAhNX+jREDVIFnv0agB9qtcnRb06K4OHtLRxWow=";
  };

  meta = {
    description = "Vulkan Header files and API registry";
    homepage = "https://www.lunarg.com";
    platforms = lib.platforms.unix;
    license = lib.licenses.asl20;
    maintainers = [ ];
  };
})
