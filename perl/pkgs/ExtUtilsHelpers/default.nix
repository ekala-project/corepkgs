{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "ExtUtils-Helpers";
  version = "0.026";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/ExtUtils-Helpers-0.026.tar.gz";
    hash = "sha256-3pAbZ5CkVXz07JCBSeA1eDsSW/EV65ZA/rG8HCTDNBY=";
  };
  meta = {
    description = "Various portability utilities for module builders";
  };
}
