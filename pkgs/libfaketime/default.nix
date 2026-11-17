{
  lib,
  stdenv,
  fetchFromGitHub,
  coreutils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libfaketime";
  version = "0.9.14";

  src = fetchFromGitHub {
    owner = "wolfcw";
    repo = "libfaketime";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ZKbwRAhyPiJUEaKcI39JDjpOqZRGE4tBjpOAxr9yPXw=";
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

  meta = {
    description = "Report faked system time to programs without having to change the system-wide time";
    homepage = "https://github.com/wolfcw/libfaketime/";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    mainProgram = "faketime";
  };
})
