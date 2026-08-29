{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "XML-Writer";
  version = "0.900";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JO/JOSEPHW/XML-Writer-0.900.tar.gz";
    hash = "sha256-c8j1vT7PKzUPStrm1mdtUuCOzC199KnwifpoNg1ADR8=";
  };
  meta = {
    description = "Module for creating a XML document object oriented with on the fly validating towards the given DTD";
    license = with lib.licenses; [ gpl1Only ];
  };
}
