{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  perl,
  pkg-config,
  python3,
  xmlto,
  zip,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zziplib";
  version = "0.13.80";

  src = fetchFromGitHub {
    owner = "gdraheim";
    repo = "zziplib";
    tag = "v${finalAttrs.version}";
    hash = "sha256-vvPcQBRk1iIPNk5qI7N0Nv9JWndVfFH6oGxyr9ZIt0g=";
  };

  nativeBuildInputs = [
    cmake.minimal
    cmake.configurePhaseHook
    perl
    pkg-config
    python3
    xmlto
    zip
  ];

  buildInputs = [
    zlib
  ];

  cmakeFlags = [
    "-DZZIP_TESTCVE=OFF"
    "-DBUILD_SHARED_LIBS=True"
    "-DBUILD_STATIC_LIBS=False"
    "-DBUILD_TESTS=OFF"
    "-DMSVC_STATIC_RUNTIME=OFF"
    "-DZZIPSDL=OFF"
    "-DZZIPTEST=OFF"
    "-DZZIPWRAP=OFF"
    "-DBUILDTESTS=OFF"
  ];

  meta = {
    homepage = "https://github.com/gdraheim/zziplib";
    description = "Library to extract data from files archived in a zip file";
    license = with lib.licenses; [
      lgpl2Plus
      mpl11
    ];
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
