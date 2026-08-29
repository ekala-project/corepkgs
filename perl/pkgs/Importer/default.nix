{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Importer";
  version = "0.026";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Importer-0.026.tar.gz";
    hash = "sha256-4I+oThPLmYt6iX/I7Jw0WfzBcWr/Jcw0Pjbvh1iRsO8=";
  };
  meta = {
    description = "Alternative but compatible interface to modules that export symbols";
  };
}
