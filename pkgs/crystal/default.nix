{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  llvmPackages,
  openssl,
  pcre2,
  libevent,
  libyaml,
  zlib,
  libxml2,
  gmp,
  boehmgc,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "crystal";
  version = "1.20.3";

  src = fetchurl {
    url = "https://github.com/crystal-lang/crystal/releases/download/${finalAttrs.version}/crystal-${finalAttrs.version}-1-linux-x86_64.tar.gz";
    hash = "sha256-ti6iWyR3E/tj3Jkr60WbytiVVGXcwRoYH9Ik1OyVWmI=";
  };

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    llvmPackages.llvm
    openssl
    pcre2
    libevent
    libyaml
    zlib
    libxml2
    gmp
    boehmgc
  ];

  # Crystal binary distribution - no build needed
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out/

    # Wrap crystal to ensure it finds its dependencies
    wrapProgram $out/bin/crystal \
      --prefix PATH : ${
        lib.makeBinPath [
          stdenv.cc
          llvmPackages.llvm
          pkg-config
        ]
      } \
      --set CRYSTAL_LIBRARY_PATH ${lib.makeLibraryPath finalAttrs.buildInputs}

    runHook postInstall
  '';

  passthru = {
    majorVersion = lib.versions.major finalAttrs.version;
    minorVersion = lib.versions.majorMinor finalAttrs.version;
  };

  meta = {
    description = "Fast and statically typed, compiled language with Ruby-like syntax";
    homepage = "https://crystal-lang.org/";
    changelog = "https://github.com/crystal-lang/crystal/releases/tag/${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ]; # Binary distribution
    mainProgram = "crystal";
    maintainers = [ ];
  };
})
