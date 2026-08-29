{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "IO-Stringy";
  version = "2.113";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CA/CAPOEIRAB/IO-Stringy-2.113.tar.gz";
    hash = "sha256-USIPyvn2amObadJR17B1e/QgL0+d69Rb3TQaaspi/k4=";
  };
  meta = {
    description = "I/O on in-core objects like strings and arrays";
  };
}
