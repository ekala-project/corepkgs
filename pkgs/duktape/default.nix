{
  lib,
  stdenv,
  fetchurl,
  fixDarwinDylibNames,
  validatePkgConfig,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "duktape";
  version = "2.7.0";
  src = fetchurl {
    url = "http://duktape.org/duktape-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-kPjS+otVZ8aJmDDd7ywD88J5YLEayiIvoXqnrGE8KJA=";
  };

  # https://github.com/svaarala/duktape/issues/2464
  LDFLAGS = [ "-lm" ];

  nativeBuildInputs = [
    validatePkgConfig
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ fixDarwinDylibNames ];

  buildPhase = ''
    make -f Makefile.cmdline
  ''
  + lib.optionalString (!stdenv.hostPlatform.isStatic) ''
    make INSTALL_PREFIX="$out" -f Makefile.sharedlibrary
  '';

  installPhase = ''
    install -d $out/bin
    install -m755 duk $out/bin/
  ''
  + lib.optionalString (!stdenv.hostPlatform.isStatic) ''
    install -d $out/lib/pkgconfig
    install -d $out/include

    make INSTALL_PREFIX="$out" -f Makefile.sharedlibrary install

    # Add -lm to pkg-config Libs so consumers link libm (needed for IFUNC ceil/floor)
    substituteInPlace $out/lib/pkgconfig/duktape.pc \
      --replace-fail 'Libs: -L''${libdir} -lduktape' 'Libs: -L''${libdir} -lduktape -lm'
  '';

  passthru.tests = {
    pkg-config = testers.pkg-config.hasModules {
      package = finalAttrs.finalPackage;
    };
    testLink = testers.pkg-config.testLink {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Embeddable Javascript engine, with a focus on portability and compact footprint";
    homepage = "https://duktape.org/";
    downloadPage = "https://duktape.org/download.html";
    license = lib.licenses.mit;
    mainProgram = "duk";
    pkgConfigModules = [ "duktape" ];
    platforms = lib.platforms.all;
  };
})
