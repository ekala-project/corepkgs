{
  buildPerlPackage,
  fetchurl,
  IOString,
  lib,
}:

buildPerlPackage {
  pname = "Font-TTF";
  version = "1.06";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BH/BHALLISSY/Font-TTF-1.06.tar.gz";
    hash = "sha256-S2l9REJZdZ6gLSxELJv/5f/hTJIUCEoB90NpOpRMwpM=";
  };
  buildInputs = [ IOString ];
  meta = {
    description = "TTF font support for Perl";
    license = with lib.licenses; [ artistic2 ];
  };
}
