{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  libsass,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sassc";
  version = "3.6.2";

  src = fetchFromGitHub {
    owner = "sass";
    repo = "sassc";
    rev = finalAttrs.version;
    hash = "sha256-jcs3+orRqKt9C3c2FTdeaj4H2rBP74lW3HF8CHSm7lQ=";
  };

  postPatch = ''
    export SASSC_VERSION=${finalAttrs.version}
  '';

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = [ libsass ];

  meta = {
    description = "Front-end for libsass";
    homepage = "https://github.com/sass/sassc/";
    license = lib.licenses.mit;
    mainProgram = "sassc";
    platforms = lib.platforms.unix;
  };
})
