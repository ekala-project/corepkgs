{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "XML-NamespaceSupport";
  version = "1.12";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz";
    hash = "sha256-R+mVhZ+N0EE6o/ItNQxKYtplLoVCZ6oFhq5USuK65e8=";
  };
  meta = {
    description = "Simple generic namespace processor";
  };
}
