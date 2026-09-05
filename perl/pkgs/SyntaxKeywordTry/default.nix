{
  buildPerlModule,
  fetchurl,
  Test2Suite,
  XSParseKeyword,
}:

buildPerlModule {
  pname = "Syntax-Keyword-Try";
  version = "0.31";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PEVANS/Syntax-Keyword-Try-0.31.tar.gz";
    hash = "sha256-e8YkLXRjeJgqWZs03jXwfT3syeCdVkb4+juH9FlBSko=";
  };
  buildInputs = [ Test2Suite ];
  propagatedBuildInputs = [ XSParseKeyword ];
  meta = {
    description = "Try/catch/finally syntax for perl";

  };
}
