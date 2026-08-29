{
  buildPerlPackage,
  fetchurl,
  TestBase,
}:

buildPerlPackage {
  pname = "Test-YAML";
  version = "1.07";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TI/TINITA/Test-YAML-1.07.tar.gz";
    hash = "sha256-HzANA09GKYy5KWCRLMBLrDP7J/BbiFLY8FHhELnNmV8=";
  };
  buildInputs = [ TestBase ];
  meta = {
    description = "Testing Module for YAML Implementations";
    mainProgram = "test-yaml";
  };
}
