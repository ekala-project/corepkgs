{
  buildPerlPackage,
  fetchurl,
  HTTPDate,
}:

buildPerlPackage {
  pname = "File-Listing";
  version = "6.16";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PL/PLICEASE/File-Listing-6.16.tar.gz";
    hash = "sha256-GJs6E/wKG6QSudnsWQHp5eREzHRrnwFW1DmTcNM2VcY=";
  };
  propagatedBuildInputs = [ HTTPDate ];
  meta = {
    description = "Parse directory listing";
  };
}
