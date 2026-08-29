{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Capture-Tiny";
  version = "0.48";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/Capture-Tiny-0.48.tar.gz";
    hash = "sha256-bCMRPoe605MwjJCiBwE+UF9lknRzZjjYx5usnGfMPhk=";
  };
  meta = {
    description = "Capture STDOUT and STDERR from Perl, XS or external programs";
    homepage = "https://github.com/dagolden/Capture-Tiny";
    license = with lib.licenses; [ asl20 ];
  };
}
