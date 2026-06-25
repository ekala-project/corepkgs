{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libx11,
  libxau,
  libxcb,
  libxdmcp,
  xorg,
  libxrandr ? xorg.libXrandr,
  wayland,
  vulkan-headers,
  addDriverRunpath,
  enableX11 ? (libxrandr != null),
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vulkan-loader";
  version = "1.4.341.0";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Loader";
    rev = "vulkan-sdk-${finalAttrs.version}";
    hash = "sha256-OcguNyi1yZ2OMnI2HSrx+pYvk4RHbn6IGZqnYwWGmB0=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs =
    [
      vulkan-headers
    ]
    ++ lib.optionals enableX11 [
      libx11
      libxau
      libxcb
      libxdmcp
      libxrandr
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      wayland
    ];

  cmakeFlags =
    [
      "-DCMAKE_INSTALL_INCLUDEDIR=${vulkan-headers}/include"
      (lib.cmakeBool "BUILD_WSI_XCB_SUPPORT" enableX11)
      (lib.cmakeBool "BUILD_WSI_XLIB_SUPPORT" enableX11)
    ]
    ++ lib.optional stdenv.hostPlatform.isLinux "-DSYSCONFDIR=${addDriverRunpath.driverLink}/share"
    ++ lib.optional (stdenv.buildPlatform != stdenv.hostPlatform) "-DUSE_GAS=OFF";

  outputs = [
    "out"
    "dev"
  ];

  meta = {
    description = "LunarG Vulkan loader";
    homepage = "https://www.lunarg.com";
    platforms = lib.platforms.unix;
    license = lib.licenses.asl20;
    maintainers = [ ];
    pkgConfigModules = [ "vulkan" ];
  };
})
