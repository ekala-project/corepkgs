{
  BFlags,
  buildPerlPackage,
  fetchurl,
  IPCRun,
  lib,
  Opcodes,
  stdenv,
}:

buildPerlPackage {
  pname = "B-C";
  version = "1.57";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RU/RURBAN/B-C-1.57.tar.gz";
    hash = "sha256-BFKmEdNDrfnZX86ra6a2YXbjrX/MzlKAkiwOQx9RSf8=";
  };
  propagatedBuildInputs = [
    BFlags
    IPCRun
    Opcodes
  ];
  env = lib.optionalAttrs stdenv.cc.isGNU {
    NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";
  };
  doCheck = false; # test fails
  meta = {
    description = "Perl compiler";
    homepage = "https://github.com/rurban/perl-compiler";
    mainProgram = "perlcc";
  };
}
