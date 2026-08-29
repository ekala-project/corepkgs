{
  buildPerlPackage,
  fetchurl,
  IPCRun3,
  lib,
  Test2Suite,
  TestSimple13,
}:

buildPerlPackage {
  pname = "Test2-Plugin-NoWarnings";
  version = "0.09";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Test2-Plugin-NoWarnings-0.09.tar.gz";
    hash = "sha256-vj3YAAQu7zYr8X0gVs+ek03ukczOmOTxeLj7V3Ly+3Q=";
  };
  buildInputs = [
    IPCRun3
    Test2Suite
  ];
  propagatedBuildInputs = [ TestSimple13 ];
  meta = {
    description = "Fail if tests warn";
    license = with lib.licenses; [ artistic2 ];
  };
}
