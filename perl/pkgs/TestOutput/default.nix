{
  buildPerlPackage,
  CaptureTiny,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Test-Output";
  version = "1.034";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BD/BDFOY/Test-Output-1.034.tar.gz";
    hash = "sha256-zULigBwNK0gtGMn7SwbHVwVIGLy7KCTl378zrXo9aaA=";
  };
  propagatedBuildInputs = [ CaptureTiny ];
  meta = {
    description = "Utilities to test STDOUT and STDERR messages";
    license = with lib.licenses; [ artistic2 ];
  };
}
