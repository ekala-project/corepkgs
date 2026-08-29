{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Digest-SHA1";
  version = "2.13";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GA/GAAS/Digest-SHA1-2.13.tar.gz";
    hash = "sha256-aMHawhh0IfDrer9xRSoG8ZAYG4/Eso7e31uQKW+5Q8w=";
  };
  meta = {
    description = "Perl interface to the SHA-1 algorithm";
  };
}
