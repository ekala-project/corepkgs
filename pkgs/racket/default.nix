# Racket — minimal distribution (includes raco package manager)
{
  lib,
  stdenv,
  fetchurl,
  libiconv,
  zlib,
  lz4,
  ncurses,
  openssl,
  sqlite,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "racket";
  version = "9.3";

  src = fetchurl {
    url = "https://mirror.racket-lang.org/installers/${finalAttrs.version}/racket-minimal-${finalAttrs.version}-src.tgz";
    hash = "sha256-Gb3E+VB3N+f0oRtkEdGEaDwza1lC0HAN2vL0xU1jkUY=";
  };

  buildInputs = [
    libiconv.real
    zlib
    lz4
    ncurses
    openssl
    sqlite.out
  ];

  preConfigure = ''
    mkdir src/build
    cd src/build
  '';

  configureScript = "../configure";

  configureFlags = [
    "--enable-csonly"
    "--enable-liblz4"
    "--enable-libz"
    "--disable-libs"
    "--enable-shared"
  ];

  dontAddStaticConfigureFlags = true;

  postFixup =
    let
      configureInstallation = builtins.path {
        name = "configure-installation.rkt";
        path = ./configure-installation.rkt;
      };
    in
    ''
      $out/bin/racket -U -u ${configureInstallation}
    '';

  meta = {
    description = "Programmable programming language (minimal distribution)";
    homepage = "https://racket-lang.org/";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "racket";
    platforms = lib.platforms.linux;
  };
})
