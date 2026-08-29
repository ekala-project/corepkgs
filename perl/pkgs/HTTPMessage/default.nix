{
  buildPerlPackage,
  Clone,
  EncodeLocale,
  fetchurl,
  HTTPDate,
  IOHTML,
  LWPMediaTypes,
  TestNeeds,
  TryTiny,
  URI,
}:

buildPerlPackage {
  pname = "HTTP-Message";
  version = "6.45";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Message-6.45.tar.gz";
    hash = "sha256-AcuEBmEqP3OIQtHpcxOuTYdIcNG41tZjMfFgAJQ9TL4=";
  };
  buildInputs = [
    TestNeeds
    TryTiny
  ];
  propagatedBuildInputs = [
    Clone
    EncodeLocale
    HTTPDate
    IOHTML
    LWPMediaTypes
    URI
  ];
  meta = {
    description = "HTTP style message (base class)";
    homepage = "https://github.com/libwww-perl/HTTP-Message";
  };
}
