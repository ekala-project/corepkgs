{
  buildPerlPackage,
  FCGIClient,
  fetchurl,
  lib,
  stdenv,
}:

buildPerlPackage {
  pname = "FCGI";
  version = "0.82";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/FCGI-0.82.tar.gz";
    hash = "sha256-TH1g4m2iwH8Fik40UCHpJQUnOzPJVCIVl34IRhHwns8=";
  };
  buildInputs = [ FCGIClient ];
  postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
    sed -i '/use IO::File/d' Makefile.PL
  '';
  meta = {
    description = "Fast CGI module";
    license = with lib.licenses; [ oml ];
  };
}
