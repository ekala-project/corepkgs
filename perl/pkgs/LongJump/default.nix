{
  buildPerlPackage,
  fetchurl,
  Test2Suite,
}:

buildPerlPackage {
  pname = "Long-Jump";
  version = "0.000001";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Long-Jump-0.000001.tar.gz";
    hash = "sha256-1dZFbYaZK1Wdj2b8kJYPkZKSzTgDwTQD+qxXV2LHevQ=";
  };
  buildInputs = [ Test2Suite ];
  meta = {
    description = "Mechanism for returning to a specific point from a deeply nested stack";
  };
}
