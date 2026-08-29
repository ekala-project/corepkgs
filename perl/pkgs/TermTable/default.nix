{
  buildPerlPackage,
  fetchurl,
  Importer,
}:

buildPerlPackage {
  pname = "Term-Table";
  version = "0.017";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Term-Table-0.017.tar.gz";
    hash = "sha256-8R20JorYBE9uGhrJU0ygzTrXecQAb/83+uUA25j6yRo=";
  };
  propagatedBuildInputs = [ Importer ];
  meta = {
    description = "Format a header and rows into a table";
  };
}
