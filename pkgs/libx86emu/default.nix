{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libx86emu";
  version = "3.7";

  src = fetchFromGitHub {
    owner = "wfeldt";
    repo = "libx86emu";
    rev = finalAttrs.version;
    sha256 = "sha256-ilAmGlkMeuG0FlygMdE3NreFPJJF6g/26C8C5grvjrk=";
  };

  nativeBuildInputs = [ perl ];

  postUnpack = "rm $sourceRoot/git2log";
  patchPhase = ''
    echo "${finalAttrs.version}" > VERSION
    substituteInPlace Makefile --replace "/usr" "/"
  '';

  buildFlags = [
    "shared"
    "CC=${stdenv.cc.targetPrefix}cc"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration";

  enableParallelBuilding = true;

  installFlags = [
    "DESTDIR=$(out)"
    "LIBDIR=/lib"
  ];

  meta = {
    description = "x86 emulation library";
    license = lib.licenses.bsd2;
    homepage = "https://github.com/wfeldt/libx86emu";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
