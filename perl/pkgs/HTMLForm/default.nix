{
  buildPerlPackage,
  fetchurl,
  HTMLParser,
  TestWarnings,
  URI,
}:

buildPerlPackage {
  pname = "HTML-Form";
  version = "6.11";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SI/SIMBABQUE/HTML-Form-6.11.tar.gz";
    hash = "sha256-Q7+qcIc5NIfS1RJhoap/b4Gpex2P73pI/PbvMrFtZFQ=";
  };
  buildInputs = [ TestWarnings ];
  propagatedBuildInputs = [
    HTMLParser
    URI
  ];
  meta = {
    description = "Class that represents an HTML form element";
    homepage = "https://github.com/libwww-perl/HTML-Form";
  };
}
