{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Font-AFM";
  version = "1.20";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GA/GAAS/Font-AFM-1.20.tar.gz";
    hash = "sha256-MmcRZtoyWWoPa6rNDBIzglpgrK8lgF15yBo/GNYIi8E=";
  };
  meta = {
    description = "Interface to Adobe Font Metrics files";
  };
}
