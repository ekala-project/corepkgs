{
  buildPerlPackage,
  fetchurl,
  lib,
  libpng,
  libx11,
  stdenv,
}:

buildPerlPackage {
  pname = "Tk";
  version = "804.036";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SR/SREZIC/Tk-804.036.tar.gz";
    hash = "sha256-Mqpycaa9/twzMBGbOCXa3dCqS1yTb4StdOq7kyogCl4=";
  };
  patches = [
    # Fix failing configure test due to implicit int return value of main, which results
    # in an error with clang 16.
    ./tk-configure-implicit-int-fix.patch
  ];
  postPatch = ''
    substituteInPlace pTk/mTk/additions/imgWindow.c \
      --replace-fail '"X11/Xproto.h"' "<X11/Xproto.h>"
    substituteInPlace PNG/zlib/Makefile.in \
      --replace-fail '$(AR) $@' '$(AR) rc $@'
    substituteInPlace PNG/libpng/scripts/makefile.gcc \
      --replace-fail 'AR_RC = ar rcs' 'AR_RC = ${stdenv.cc.targetPrefix}ar rcs'
    substituteInPlace JPEG/jpeg/makefile.cfg \
      --replace-fail 'AR= ar rc' 'AR= ${stdenv.cc.targetPrefix}ar rc'
  '';
  makeMakerFlags = [
    "AR=${stdenv.cc.targetPrefix}ar"
    "X11INC=${libx11.dev}/include"
    "X11LIB=${libx11.out}/lib"
  ];
  buildInputs = [
    libx11
    libpng
  ];
  env = lib.optionalAttrs stdenv.cc.isGNU {
    NIX_CFLAGS_COMPILE = toString [
      "-Wno-error=implicit-int"
      "-Wno-error=incompatible-pointer-types"
    ];
  };
  doCheck = false; # Expects working X11.
  meta = {
    description = "Tk - a Graphical User Interface Toolkit";
    license = with lib.licenses; [ tcltk ];
  };
}
