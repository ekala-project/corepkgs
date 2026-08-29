{
  buildPerlModule,
  fetchurl,
  lib,
}:

buildPerlModule {
  pname = "SGMLSpm";
  version = "1.1";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RA/RAAB/SGMLSpm-1.1.tar.gz";
    hash = "sha256-VQySRSkcjfIkL36I95IaD2NsfuySxkRBjn2Jz+pwsr0=";
  };
  meta = {
    description = "Library for parsing the output from SGMLS and NSGMLS parsers";
    license = with lib.licenses; [ gpl2Plus ];
    mainProgram = "sgmlspl.pl";
  };
}
