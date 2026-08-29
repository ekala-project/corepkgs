{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "boolean";
  version = "0.46";
  src = fetchurl {
    url = "mirror://cpan/authors/id/I/IN/INGY/boolean-0.46.tar.gz";
    hash = "sha256-lcCICFw+g79oD+bOFtgmTsJjEEkPfRaA5BbqehGPFWo=";
  };
  meta = {
    description = "Boolean support for Perl";
    homepage = "https://github.com/ingydotnet/boolean-pm";
  };
}
