{
  lib,
  stdenv,
  buildPackages,
  fetchurl,
  gfortran,
  m4,
  perl,
  which,
  python3,
  openssl,
  zlib,
  libxml2,
  cacert,
  cmake,
  pkg-config,
  patchelf,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "julia";
  version = "1.12.6";

  src = fetchurl {
    url = "https://github.com/JuliaLang/julia/releases/download/v${finalAttrs.version}/julia-${finalAttrs.version}-full.tar.gz";
    hash = "sha256-cR86qNbsXJAEWT6489U+NWTNdZrLqK1K2ulnr8IDMsw=";
  };

  postPatch = ''
    patchShebangs .
  ''
  + lib.optionalString (lib.versionAtLeast finalAttrs.version "1.11") ''
    substituteInPlace deps/curl.mk \
      --replace-fail 'jxf $(notdir $<)' \
                     'jxf $(notdir $<) && sed -i "s|/usr/bin/env perl|${lib.getExe buildPackages.perl}|" curl-$(CURL_VER)/scripts/cd2nroff'
  ''
  + lib.optionalString (lib.versionOlder finalAttrs.version "1.12") ''
    substituteInPlace deps/tools/common.mk \
      --replace-fail "CMAKE_COMMON := " "CMAKE_COMMON := ${lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.10"} "
  ''
  + lib.optionalString (lib.versionAtLeast finalAttrs.version "1.12") ''
    substituteInPlace deps/openssl.mk \
      --replace-fail 'cd $(dir $<) && $(TAR) -zxf $<' \
                     'cd $(dir $<) && $(TAR) -zxf $< && sed -i "s|/usr/bin/env perl|${lib.getExe buildPackages.perl}|" openssl-$(OPENSSL_VER)/Configure'
  '';

  nativeBuildInputs = [
    gfortran
    m4
    perl
    which
    python3
    openssl
    cmake
    pkg-config
    patchelf
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    gfortran.cc.lib
    libxml2
    zlib
    cacert
  ];

  makeFlags = [
    "prefix=$(out)"
    "USE_BINARYBUILDER=0"
    "BUILD_DOCS=0"
  ]
  ++ lib.optionals stdenv.hostPlatform.isx86_64 [
    "JULIA_CPU_TARGET=generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
  ];

  # Julia's build system expects to build in-tree
  dontUseCmakeConfigure = true;

  enableParallelBuilding = true;

  doCheck = false; # Tests require network and are slow
  doInstallCheck = false;
  dontStrip = true; # Julia does its own stripping

  postInstall = ''
    # Remove test files to reduce closure size
    rm -rf $out/share/julia/test

    # Julia-specific cleanup
    find $out/share/julia -name '*.a' -delete
  '';

  # remove forbidden reference to $TMPDIR
  preFixup = ''
    for file in libcurl.so libgmpxx.so libmpfr.so; do
      patchelf --shrink-rpath --allowed-rpath-prefixes ${builtins.storeDir} "$out/lib/julia/$file"
    done
  '';

  passthru = {
    majorVersion = lib.versions.major finalAttrs.version;
    minorVersion = lib.versions.majorMinor finalAttrs.version;
  };

  meta = {
    description = "High-level, high-performance dynamic language for technical computing";
    longDescription = ''
      Julia is a high-level, high-performance dynamic programming language for
      technical computing, with syntax that is familiar to users of other
      technical computing environments.

      This package is built from source using system libraries where possible
      to reduce duplication and improve NAR compression.
    '';
    homepage = "https://julialang.org/";
    changelog = "https://github.com/JuliaLang/julia/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "julia";
    maintainers = [ ];
    # Building Julia from source takes significant time
    timeout = 7200; # 2 hours
  };
})
