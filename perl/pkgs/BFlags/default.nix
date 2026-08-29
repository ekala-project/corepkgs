{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "B-Flags";
  version = "0.17";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RU/RURBAN/B-Flags-0.17.tar.gz";
    hash = "sha256-wduX0BMVvtEJtMSJWM0yGVz8nvXTt3B+tHhAwdV8ELI=";
  };
  meta = {
    description = "Friendlier flags for B";
    license = with lib.licenses; [
      artistic1
      gpl1Only
    ];
  };
}
