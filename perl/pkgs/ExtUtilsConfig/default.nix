{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "ExtUtils-Config";
  version = "0.008";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/ExtUtils-Config-0.008.tar.gz";
    hash = "sha256-rlEE9jRlDc6KebftE/tZ1no5whOmd2z9qj7nSeYvGow=";
  };
  meta = {
    description = "Wrapper for perl's configuration";
  };
}
