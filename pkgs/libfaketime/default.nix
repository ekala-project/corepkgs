{
  lib,
  stdenv,
  fetchFromGitHub,
  coreutils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libfaketime";
  version = "0.9.12";

  src = fetchFromGitHub {
    owner = "wolfcw";
    repo = "libfaketime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Hd59b7pc6GIDvRR6EEosr/f8sKuV2q7RU7gDSaGFp3Y=";
  };

  postPatch = ''
    patchShebangs test src
    substituteInPlace src/faketime.c \
      --replace-fail "static const char *date_cmd = \"date\";" \
        "static const char *date_cmd = \"${lib.getExe' coreutils "date"}\";"
  '';

  env = {
    PREFIX = placeholder "out";
    LIBDIRNAME = "/lib";
  };

  strictDeps = true;
  enableParallelBuilding = true;

  meta = {
    description = "Report faked system time to programs without having to change the system-wide time";
    homepage = "https://github.com/wolfcw/libfaketime/";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    mainProgram = "faketime";
  };
})
