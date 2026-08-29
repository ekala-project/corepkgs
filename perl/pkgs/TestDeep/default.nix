{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Test-Deep";
  version = "1.204";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Test-Deep-1.204.tar.gz";
    hash = "sha256-tlkfbM3YU8fvyf88V1Y3BAMhHP/kYEfwgrHNFhGoTl8=";
  };
  meta = {
    description = "Extremely flexible deep comparison";
    homepage = "https://github.com/rjbs/Test-Deep";
  };
}
