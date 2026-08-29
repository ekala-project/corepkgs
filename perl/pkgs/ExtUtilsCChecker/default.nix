{
  buildPerlModule,
  fetchurl,
  TestFatal,
}:

buildPerlModule {
  pname = "ExtUtils-CChecker";
  version = "0.11";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PEVANS/ExtUtils-CChecker-0.11.tar.gz";
    hash = "sha256-EXc2Z343/GEfW3Y3TX+VLhlw64Dh9q1RUNUW565TG/U=";
  };
  buildInputs = [ TestFatal ];
  meta = {
    description = "Configure-time utilities for using C headers";
  };
}
