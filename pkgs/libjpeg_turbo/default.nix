{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nasm,
  java,
  enableJava ? false, # whether to build the java wrapper
  enableJpeg7 ? false, # whether to build libjpeg with v7 compatibility
  enableJpeg8 ? false, # whether to build libjpeg with v8 compatibility
  enableStatic ? stdenv.hostPlatform.isStatic,
  enableShared ? !stdenv.hostPlatform.isStatic,

  # for passthru.tests
  dvgrab ? null,
  epeg ? null,
  gd,
  graphicsmagick ? null,
  imagemagick,
  jhead ? null,
  libjxl,
  mjpegtools ? null,
  opencv ? null,
  python3,
  vips ? null,
  testers,
  nix-update-script,
}:

assert !(enableJpeg7 && enableJpeg8); # pick only one or none, not both
assert enableJava -> java != null;

stdenv.mkDerivation (finalAttrs: {
  pname = "libjpeg-turbo";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "libjpeg-turbo";
    repo = "libjpeg-turbo";
    tag = finalAttrs.version;
    hash = "sha256-SPxWCDt9hFQ8uRaaKLkpWp9oPhfcRkDBm5MarTgdmV4=";
  };

  patches =
    [ ]
    ++ lib.optionals stdenv.hostPlatform.isMinGW [
      ./mingw-boolean.patch
    ];

  outputs = [
    "bin"
    "dev"
    "out"
    "man"
    "doc"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    nasm
  ]
  ++ lib.optionals enableJava [
    java
  ];

  cmakeEntries = {
    ENABLE_STATIC = enableStatic;
    ENABLE_SHARED = enableShared;
    ${if enableJava then "WITH_JAVA" else null} = "1";
    ${if enableJpeg7 then "WITH_JPEG7" else null} = "1";
    ${if enableJpeg8 then "WITH_JPEG8" else null} = "1";
    # https://github.com/libjpeg-turbo/libjpeg-turbo/issues/428
    # https://github.com/libjpeg-turbo/libjpeg-turbo/commit/88bf1d16786c74f76f2e4f6ec2873d092f577c75
    ${if stdenv.hostPlatform.isRiscV then "FLOATTEST" else null} = "fp-contract";
  };

  doInstallCheck = true;
  installCheckTarget = "test";

  passthru = {
    updateScript = nix-update-script { };
    dev_private = throw "not supported anymore";
    tests = {
      inherit
        gd
        imagemagick
        libjxl
        ;
      inherit (python3.pkgs) pillow imread pyturbojpeg;
      pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
      pkg-config-install = testers.pkg-config.testInstall finalAttrs.finalPackage { };
    }
    // lib.optionalAttrs (dvgrab != null) { inherit dvgrab; }
    // lib.optionalAttrs (epeg != null) { inherit epeg; }
    // lib.optionalAttrs (graphicsmagick != null) { inherit graphicsmagick; }
    // lib.optionalAttrs (jhead != null) { inherit jhead; }
    // lib.optionalAttrs (mjpegtools != null) { inherit mjpegtools; }
    // lib.optionalAttrs (opencv != null) { inherit opencv; }
    // lib.optionalAttrs (vips != null) { inherit vips; };
  };

  meta = {
    homepage = "https://libjpeg-turbo.org/";
    description = "Faster (using SIMD) libjpeg implementation";
    license = lib.licenses.ijg; # and some parts under other BSD-style licenses
    changelog = "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/tag/${finalAttrs.version}";
    pkgConfigModules = [
      "libjpeg"
      "libturbojpeg"
    ];
    platforms = lib.platforms.all;
    identifiers.cpeParts = {
      vendor = "libjpeg-turbo";
      product = "libjpeg-turbo";
    };
  };
})
