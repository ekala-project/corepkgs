{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Crypt-URandom";
  version = "0.54";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DD/DDICK/Crypt-URandom-0.54.tar.gz";
    hash = "sha256-SnPNOUkzMo2khKrrhkXXNbNUZd9gEJ5VngoosGYFOlc=";
  };
  meta = {
    description = "Provide non blocking randomness";

  };
}
