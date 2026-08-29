{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Proc-ProcessTable";
  version = "0.636";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JW/JWB/Proc-ProcessTable-0.636.tar.gz";
    hash = "sha256-lEIk/7APwe81BpYzdwoK/ahiO1x1MtHkq0ip3zlIkP0=";
  };
  meta = {
    description = "Perl extension to access the unix process table";
    license = with lib.licenses; [ artistic2 ];
  };
}
