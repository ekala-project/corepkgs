{
  buildPerlPackage,
  DevelCycle,
  fetchurl,
  lib,
  PadWalker,
}:

buildPerlPackage {
  pname = "Test-Memory-Cycle";
  version = "1.06";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PETDANCE/Test-Memory-Cycle-1.06.tar.gz";
    hash = "sha256-nVPd/clkzYRUyw2kxpW2o65HtFg5KRw0y52NHPqrMgI=";
  };
  propagatedBuildInputs = [
    DevelCycle
    PadWalker
  ];
  meta = {
    description = "Verifies code hasn't left circular references";
    license = with lib.licenses; [ artistic2 ];
  };
}
