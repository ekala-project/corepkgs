{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Params-Util";
  version = "1.102";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RE/REHSACK/Params-Util-1.102.tar.gz";
    hash = "sha256-SZuxtILbJP2id6UVJVlq0JLCvVHdUI+o/sLp+EkJdAI=";
  };
  meta = {
    description = "Simple, compact and correct param-checking functions";
  };
}
