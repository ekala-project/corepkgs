{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "blocksruntime";
  version = "0-unstable-2017-10-28";

  src = fetchFromGitHub {
    owner = "mackyle";
    repo = "blocksruntime";
    rev = "9cc93ae2b58676c23fd02cf0c686fa15b7a3ff81";
    sha256 = "sha256-pQMNZBgkF4uADOVCWXB5J3qQt8JMe8vo6ZmbtSVA5Xo=";
  };

  buildPhase = ''
    ./buildlib ${lib.optionalString (!stdenv.hostPlatform.isStatic) "-shared"}
  '';

  installPhase = ''
    prefix="/" DESTDIR=$out ./installlib ${
      if stdenv.hostPlatform.isStatic then "-static" else "-shared"
    }
  '';

  checkPhase = ''
    ./checktests
  '';

  doCheck = false; # hasdescriptor.c test fails, hrm.

  meta = {
    description = "Installs the BlocksRuntime library from the compiler-rt";
    homepage = "https://github.com/mackyle/blocksruntime";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
