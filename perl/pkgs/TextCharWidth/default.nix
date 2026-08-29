{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Text-CharWidth";
  version = "0.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/K/KU/KUBOTA/Text-CharWidth-0.04.tar.gz";
    hash = "sha256-q97V9P3ZM46J/S8dgnHESYna5b9Qrs5BthedjiMHBPg=";
  };
  meta = {
    description = "Get number of occupied columns of a string on terminal";
  };
}
