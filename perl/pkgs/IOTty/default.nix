{
  buildPerlPackage,
  fetchurl,
  lib,
  stdenv,
}:

buildPerlPackage rec {
  pname = "IO-Tty";
  version = "1.20";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TODDR/IO-Tty-${version}.tar.gz";
    hash = "sha256-sVMJ/IViOJMonLmyuI36ntHmkVa3XymThVOkW+bXMK8=";
  };
  # Fix dynamic loading not available when cross compiling
  postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
    sed -i '/use IO::File/d' Makefile.PL
  '';
  doCheck = !stdenv.hostPlatform.isDarwin; # openpty fails in the sandbox
  meta = {
    homepage = "https://github.com/toddr/IO-Tty";
    description = "Low-level allocate a pseudo-Tty, import constants";
  };
}
