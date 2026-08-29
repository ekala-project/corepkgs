{
  buildPerlPackage,
  fetchurl,
  lib,
  perl,
  XMLNamespaceSupport,
  XMLSAXBase,
}:

buildPerlPackage {
  pname = "XML-SAX";
  version = "1.02";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GR/GRANTM/XML-SAX-1.02.tar.gz";
    hash = "sha256-RQbDhwQ6pqd7RV8A9XQJ83IKp+VTSVqyU1JjtO0eoSo=";
  };
  propagatedBuildInputs = [
    XMLNamespaceSupport
    XMLSAXBase
  ];
  postPatch = ''
    substituteInPlace Makefile.PL \
      --replace-fail "\$(PERL)" "${lib.getExe perl.perlOnBuild}"
  '';
  meta = {
    description = "Simple API for XML";
  };
}
