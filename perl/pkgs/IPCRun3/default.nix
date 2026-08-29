{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "IPC-Run3";
  version = "0.048";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/IPC-Run3-0.048.tar.gz";
    hash = "sha256-PYHDzBtc/2nMqTYeLG443wNSJRrntB4v8/68hQ5GNWU=";
  };
  meta = {
    description = "Run a subprocess with input/output redirection";
    license = with lib.licenses; [
      artistic1
      gpl1Plus
      bsd3
    ];
  };
}
