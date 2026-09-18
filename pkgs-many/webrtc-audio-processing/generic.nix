{
  version,
  src-hash,
  src-url ? null,
  packageOlder,
  packageAtLeast,
  ...
}:

{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitLab,
  fetchpatch,
  abseil-cpp,
  autoreconfHook,
  meson,
  ninja,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "webrtc-audio-processing";
  inherit version;

  src =
    if packageOlder "1.0" then
      fetchurl {
        url = src-url;
        hash = src-hash;
      }
    else
      fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "pulseaudio";
        repo = "webrtc-audio-processing";
        rev = "v${version}";
        hash = src-hash;
      };

  patches =
    lib.optionals (packageOlder "1.0") [
      ./patches/v0_3/enable-riscv.patch
      ./patches/v0_3/enable-powerpc.patch
      (fetchpatch {
        name = "0001-webrtc-audio-processing-big-endian.patch";
        url = "https://gitlab.freedesktop.org/pulseaudio/pulseaudio/uploads/2994c0512aaa76ebf41ce11c7b9ba23e/webrtc-audio-processing-0.2-big-endian.patch";
        hash = "sha256-zVAj9H8SJureQd0t5O5v1je4ia8/gHJOXYxuEBEB6gg=";
      })
      (fetchpatch {
        url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/2f3c3b1d9dadc25356da4b612130bf4dea27b817/audio/webrtc-audio-processing0/files/patch-configure.ac";
        hash = "sha256-IOSW3ZLIuRXY/M+MU813M9o0Vu4mcGoAtdNRlJwESHw=";
        extraPrefix = "";
      })
      (fetchpatch {
        url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/27f26f19a34755fe4b939a7210d8ba7ee9358a0d/audio/webrtc-audio-processing0/files/patch-webrtc_base_stringutils.h";
        hash = "sha256-j85CdFpDIPhhEquwA3P0r5djnMEGVnvfsPM2bYbURt8=";
        extraPrefix = "";
      })
      (fetchpatch {
        url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/0d316feccaf89c1bd804d6001274426a7135c93a/audio/webrtc-audio-processing0/files/patch-webrtc_base_platform__thread.cc";
        hash = "sha256-MsZtNWv3bwxJLxpQaMqj34XIBhqAaO2NkBHjlFWZreA=";
        extraPrefix = "";
      })
    ]
    ++ lib.optionals (packageAtLeast "1.0" && packageOlder "2.0") [
      (fetchurl {
        url = "https://git.alpinelinux.org/aports/plain/community/webrtc-audio-processing-1/0001-rtc_base-Include-stdint.h-to-fix-build-failures.patch?id=625e19c19972e69e034c0870a31b375833d1ab5d";
        hash = "sha256-9nI22SJoU0H3CzsPSAObtCFTadtvkzdnqIh6mxmUuds=";
      })
      (fetchurl {
        url = "https://gitlab.alpinelinux.org/alpine/aports/-/raw/0630fa25465530c0e7358f00016bdc812894f67f/community/webrtc-audio-processing-1/add-loongarch-support.patch";
        hash = "sha256-Cn3KwKSSV/QJm1JW0pkEWB6OmeA0fRlVkiMU8OzXNzY=";
      })
      (fetchurl {
        url = "https://gitlab.archlinux.org/archlinux/packaging/packages/webrtc-audio-processing-1/-/raw/9de1306d3a6a78f435666453b85ba8ede0dd91ea/0001-Fix-compilation-with-GCC-15.patch";
        hash = "sha256-Ws7FRBX5+nIKWJv6cROqO5eSm5AJGyZVWrAjQ4R3n0I=";
      })
    ]
    ++ lib.optionals (packageAtLeast "2.0") [
      (fetchpatch {
        name = "gcc-15-compat.patch";
        url = "https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing/-/commit/e9c78dc4712fa6362b0c839ad57b6b46dce1ba83.diff";
        hash = "sha256-QXOtya7RA0UTV9VK4qpql5D8QcOKAn6qURZvPpWT+vg=";
      })
      ./abseil-202508.patch
    ];

  outputs = [
    "out"
    "dev"
  ];

  postPatch = lib.optionalString (packageOlder "1.0" && stdenv.hostPlatform.isMusl) ''
    substituteInPlace webrtc/base/checks.cc --replace 'defined(__UCLIBC__)' 1
  '';

  nativeBuildInputs =
    if packageOlder "1.0" then
      [
        autoreconfHook
        pkg-config
      ]
    else
      [
        meson
        meson.configurePhaseHook
        ninja
        pkg-config
      ];

  propagatedBuildInputs = lib.optionals (packageAtLeast "1.0") [
    (if packageAtLeast "2.0" then abseil-cpp.override { cxxStandard = "17"; } else abseil-cpp)
  ];

  enableParallelBuilding = packageOlder "1.0";

  mesonEntries = lib.optionalAttrs (packageAtLeast "2.0") (
    lib.optionalAttrs (!stdenv.hostPlatform.isAarch64) {
      neon = "disabled";
    }
    // lib.optionalAttrs stdenv.hostPlatform.isi686 {
      inline-sse = false;
    }
  );

  env =
    lib.optionalAttrs (packageAtLeast "1.0" && packageOlder "2.0" && stdenv.hostPlatform.isx86_32)
      {
        NIX_CFLAGS_COMPILE = "-msse2";
      };

  meta = {
    homepage = "https://www.freedesktop.org/software/pulseaudio/webrtc-audio-processing";
    description = "More Linux packaging friendly copy of the AudioProcessing module from the WebRTC project";
    license = lib.licenses.bsd3;
    badPlatforms = lib.optionals (packageAtLeast "1.0") lib.platforms.bigEndian;
    platforms =
      if packageOlder "1.0" then
        lib.intersectLists lib.platforms.unix (
          lib.platforms.arm
          ++ lib.platforms.aarch64
          ++ lib.platforms.mips
          ++ lib.platforms.power
          ++ lib.platforms.riscv
          ++ lib.platforms.x86
        )
      else if packageOlder "2.0" then
        lib.intersectLists (lib.platforms.darwin ++ lib.platforms.linux ++ lib.platforms.windows) (
          lib.platforms.arm
          ++ lib.platforms.aarch64
          ++ lib.platforms.loongarch64
          ++ lib.platforms.mips
          ++ lib.platforms.riscv
          ++ lib.platforms.x86
        )
      else
        lib.intersectLists
          (
            lib.platforms.arm
            ++ lib.platforms.aarch64
            ++ lib.platforms.mips
            ++ lib.platforms.power
            ++ lib.platforms.riscv
            ++ lib.platforms.x86
            ++ lib.platforms.loongarch64
          )
          (
            lib.platforms.linux
            ++ lib.platforms.windows
            ++ lib.platforms.freebsd
            ++ lib.platforms.netbsd
            ++ lib.platforms.openbsd
            ++ lib.platforms.darwin
          );
  };
})
