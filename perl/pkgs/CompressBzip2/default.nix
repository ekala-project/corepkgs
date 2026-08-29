{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Compress-Bzip2";
  version = "2.28";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RU/RURBAN/Compress-Bzip2-2.28.tar.gz";
    hash = "sha256-hZ+DXD9cmYgQ2LKm+eKC/5nWy2bM+lXK5+Ztr7A1EW4=";
  };
  meta = {
    description = "Interface to Bzip2 compression library";
  };
}
