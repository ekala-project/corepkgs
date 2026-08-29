{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Devel-CheckBin";
  version = "0.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TOKUHIROM/Devel-CheckBin-0.04.tar.gz";
    hash = "sha256-FX89tZwp7R1JEzpGnO53LIha1O5k6GkqkbPr/b4v4+Q=";
  };
  meta = {
    description = "Check that a command is available";
    homepage = "https://github.com/tokuhirom/Devel-CheckBin";
  };
}
