{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Opcodes";
  version = "0.14";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RU/RURBAN/Opcodes-0.14.tar.gz";
    hash = "sha256-f3NlRH5NHFuHtDCRRI8EiOZ8nwNrJsAipUCc1z00OJM=";
  };
  meta = {
    description = "More Opcodes information from opnames.h and opcode.h";
  };
}
