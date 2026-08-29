{
  buildPerlModule,
  fetchurl,
  Test2Suite,
  XSParseKeyword,
}:

buildPerlModule {
  pname = "Syntax-Keyword-Try";
  version = "0.29";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PEVANS/Syntax-Keyword-Try-0.29.tar.gz";
    hash = "sha256-zDIHGdNgjaqVFHQ6Q9rCvpnLjM2Ymx/vooUpDLHVnY8=";
  };
  buildInputs = [ Test2Suite ];
  propagatedBuildInputs = [ XSParseKeyword ];
  meta = {
    description = "Try/catch/finally syntax for perl";

  };
}
