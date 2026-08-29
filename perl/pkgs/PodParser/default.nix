{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Pod-Parser";
  version = "1.66";
  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MA/MAREKR/Pod-Parser-1.66.tar.gz";
    hash = "sha256-IpKKe//mG0UsBbu7j1IW1LnPn+KoSbd2wlUA0k0g33w=";
  };
  meta = {
    description = "Modules for parsing/translating POD format documents";
    license = with lib.licenses; [ artistic1 ];
    mainProgram = "podselect";
  };
}
