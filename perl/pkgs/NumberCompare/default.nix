{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Number-Compare";
  version = "0.03";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RC/RCLAMP/Number-Compare-0.03.tar.gz";
    hash = "sha256-gyk3N+gDtDESgwRD+1II7FIIoubqUS7VTvjk3SuICCc=";
  };
  meta = {
    description = "Numeric comparisons";
  };
}
