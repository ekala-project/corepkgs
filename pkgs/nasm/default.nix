{
  lib,
  stdenv,
  fetchurl,
  perl,
  gitUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nasm";
  version = "2.16.03";

  src = fetchurl {
    url = "https://www.nasm.us/pub/nasm/releasebuilds/${finalAttrs.version}/${finalAttrs.pname}-${finalAttrs.version}.tar.xz";
    hash = "sha256-FBKhx2C70F2wJrbA0WV6/9ZjHNCmPN229zzG1KphYUg=";
  };

  nativeBuildInputs = [ perl ];

  enableParallelBuilding = true;

  doCheck = false;

  checkPhase = ''
    runHook preCheck

    make golden
    make test

    runHook postCheck
  '';

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };

  passthru.updateScript = gitUpdater {
    url = "https://github.com/netwide-assembler/nasm.git";
    rev-prefix = "nasm-";
    ignoredVersions = "rc.*";
  };

  meta = {
    homepage = "https://www.nasm.us/";
    description = "80x86 and x86-64 assembler designed for portability and modularity";
    platforms = lib.platforms.unix;
    mainProgram = "nasm";
    license = lib.licenses.bsd2;
  };
})
