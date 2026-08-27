{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  doxygen,
  gettext,
  graphviz,
  libxslt,
  removeReferencesTo,
  libiconv,
  brotli,
  expat,
  inih,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "exiv2";
  version = "0.28.8";

  outputs = [
    "out"
    "lib"
    "dev"
    "doc"
    "man"
  ];

  src = fetchFromGitHub {
    owner = "exiv2";
    repo = "exiv2";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9Qe+lNBO24qQyKDXe7RMCqoDa61iha2QFhRpLJlCSMo=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    doxygen
    gettext
    graphviz
    libxslt
    removeReferencesTo
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
  ];

  propagatedBuildInputs = [
    brotli
    expat
    inih
    zlib
  ];

  cmakeFlags = [
    "-DEXIV2_ENABLE_NLS=ON"
    "-DEXIV2_BUILD_DOC=ON"
    "-DEXIV2_ENABLE_BMFF=ON"
  ];

  buildFlags = [
    "all"
    "doc"
  ];

  preFixup = ''
    remove-references-to -t ${stdenv.cc.cc} $lib/lib/*.so.*.*.* $out/bin/exiv2
  '';

  disallowedReferences = [ stdenv.cc.cc ];

  # causes redefinition of _FORTIFY_SOURCE
  hardeningDisable = [ "fortify3" ];

  meta = {
    homepage = "https://exiv2.org";
    description = "Library and command-line utility to manage image metadata";
    mainProgram = "exiv2";
    platforms = lib.platforms.all;
    license = lib.licenses.gpl2Plus;
  };
})
