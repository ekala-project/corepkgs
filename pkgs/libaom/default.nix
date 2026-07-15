{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  nasm,
  perl,
  cmake,
  pkg-config,
  python3,
}:

let
  isCross = stdenv.buildPlatform != stdenv.hostPlatform;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "libaom";
  version = "3.12.1";

  src = fetchzip {
    url = "https://aomedia.googlesource.com/aom/+archive/v${finalAttrs.version}.tar.gz";
    hash = "sha256-AAS6wfq4rZ4frm6+gwKoIS3+NVzPhhfW428WXJQ2tQ8=";
    stripRoot = false;
  };

  patches = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    (fetchurl {
      name = "musl.patch";
      url = "https://gitweb.gentoo.org/repo/gentoo.git/plain/media-libs/libaom/files/libaom-3.4.0-posix-c-source-ftello.patch?id=50c7c4021e347ee549164595280cf8a23c960959";
      hash = "sha256-6+u7GTxZcSNJgN7D+s+XAVwbMnULufkTcQ0s7l+Ydl0=";
    })
  ];

  nativeBuildInputs = [
    nasm
    perl
    cmake
    cmake.configurePhaseHook
    pkg-config
    python3
  ];

  env = lib.optionalAttrs stdenv.hostPlatform.isFreeBSD {
    NIX_CFLAGS_COMPILE = "-D_XOPEN_SOURCE=700";
  };

  preConfigure = ''
    # build uses `git describe` to set the build version
    cat > $NIX_BUILD_TOP/git << "EOF"
    #!${stdenv.shell}
    echo v${finalAttrs.version}
    EOF
    chmod +x $NIX_BUILD_TOP/git
    export PATH=$NIX_BUILD_TOP:$PATH
  '';

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DENABLE_TESTS=OFF"
    "-DCONFIG_TUNE_VMAF=0"
    "-DCMAKE_INSTALL_INCLUDEDIR=${placeholder "dev"}/include"
    "-DCMAKE_INSTALL_LIBDIR=${placeholder "out"}/lib"
  ]
  ++ lib.optionals (isCross && !stdenv.hostPlatform.isx86) [
    "-DCMAKE_ASM_COMPILER=${lib.getBin stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc"
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch32 [
    "-DENABLE_NEON=0"
  ];

  postFixup = ''
    # Fix broken pkgconfig paths (double slashes from cmake prefix joining)
    if [ -f "$dev/lib/pkgconfig/aom.pc" ]; then
      sed -i "s|libdir=.*|libdir=$out/lib|" "$dev/lib/pkgconfig/aom.pc"
      sed -i "s|includedir=.*|includedir=$dev/include|" "$dev/lib/pkgconfig/aom.pc"
    fi
    moveToOutput lib/libaom.a "$static"
  ''
  + lib.optionalString stdenv.hostPlatform.isStatic ''
    ln -s $static $out
  '';

  outputs = [
    "out"
    "bin"
    "dev"
    "static"
  ];

  meta = {
    description = "Alliance for Open Media AV1 codec library";
    homepage = "https://aomedia.org/av1-features/get-started/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
    outputsToInstall = [ "bin" ];
  };
})
