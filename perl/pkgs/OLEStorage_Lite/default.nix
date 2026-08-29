{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "OLE-Storage_Lite";
  version = "0.22";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JM/JMCNAMARA/OLE-Storage_Lite-0.22.tar.gz";
    hash = "sha256-0FZtbCnTl+pzY3ncUVw2hJ9rlxB89wC6glBQXJhM+WU=";
  };
  meta = {
    description = "Read and write OLE storage files";
  };
}
