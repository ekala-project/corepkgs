{
  buildPerlPackage,
  DevelGlobalDestruction,
  fetchurl,
  IPCRun3,
  lib,
  namespaceautoclean,
  ParamsValidationCompiler,
  Specio,
  TestFatal,
  TestNeeds,
}:

buildPerlPackage {
  pname = "Log-Dispatch";
  version = "2.71";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Log-Dispatch-2.71.tar.gz";
    hash = "sha256-nWDZZIw1zidUcx603rfwWAns4b1jO3TXR5Wu2exzJXA=";
  };
  propagatedBuildInputs = [
    DevelGlobalDestruction
    ParamsValidationCompiler
    Specio
    namespaceautoclean
  ];
  buildInputs = [
    IPCRun3
    TestFatal
    TestNeeds
  ];
  meta = {
    description = "Dispatches messages to one or more outputs";
    license = with lib.licenses; [ artistic2 ];
  };
}
