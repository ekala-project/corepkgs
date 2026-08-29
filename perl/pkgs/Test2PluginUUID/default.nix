{
  buildPerlPackage,
  DataUUID,
  fetchurl,
  Test2Suite,
}:

buildPerlPackage {
  pname = "Test2-Plugin-UUID";
  version = "0.002001";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Plugin-UUID-0.002001.tar.gz";
    hash = "sha256-TGyNSE1xU9h3ncFVqZKyAwlbXFqhz7Hui87c0GAYeMk=";
  };
  buildInputs = [ Test2Suite ];
  propagatedBuildInputs = [ DataUUID ];
  meta = {
    description = "Use REAL UUIDs in Test2";
  };
}
