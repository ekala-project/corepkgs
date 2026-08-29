{
  buildPerlModule,
  fetchurl,
  SUPER,
  TestWarnings,
}:

buildPerlModule {
  pname = "Test-MockModule";
  version = "0.177.0";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GF/GFRANKS/Test-MockModule-v0.177.0.tar.gz";
    hash = "sha256-G9p6SdzqdgdtQKe2psPz4V5rGchLYXHfRFNNkROPEEU=";
  };
  propagatedBuildInputs = [ SUPER ];
  buildInputs = [ TestWarnings ];
  meta = {
    description = "Override subroutines in a module for unit testing";
  };
}
