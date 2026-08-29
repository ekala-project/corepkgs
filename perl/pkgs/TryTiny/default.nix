{
  buildPerlPackage,
  CaptureTiny,
  CPANMetaCheck,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Try-Tiny";
  version = "0.31";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Try-Tiny-0.31.tar.gz";
    hash = "sha256-MwDTHYpAdbJtj0bOhkodkT4OhGfO66ZlXV0rLiBsEb4=";
  };
  buildInputs = [
    CPANMetaCheck
    CaptureTiny
  ];
  meta = {
    description = "Minimal try/catch with proper preservation of $@";
    homepage = "https://github.com/p5sagit/Try-Tiny";
    license = with lib.licenses; [ mit ];
  };
}
