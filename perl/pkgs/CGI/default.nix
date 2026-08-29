{
  buildPerlPackage,
  fetchurl,
  HTMLParser,
  lib,
  TestDeep,
  TestNoWarnings,
  TestWarn,
}:

buildPerlPackage {
  pname = "CGI";
  version = "4.59";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEEJO/CGI-4.59.tar.gz";
    hash = "sha256-be5LibiLEOd8lvPAjRm1hq74M7F6Ql1hiq19KMJi+Rw=";
  };
  buildInputs = [
    TestDeep
    TestNoWarnings
    TestWarn
  ];
  propagatedBuildInputs = [ HTMLParser ];
  meta = {
    description = "Handle Common Gateway Interface requests and responses";
    license = with lib.licenses; [ artistic2 ];
  };
}
