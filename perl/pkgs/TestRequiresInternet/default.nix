{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Test-RequiresInternet";
  version = "0.05";
  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MA/MALLEN/Test-RequiresInternet-0.05.tar.gz";
    hash = "sha256-u6ezKhzA1Yzi7CCyAKc0fGljFkHoyuj/RWetJO8egz4=";
  };
  meta = {
    description = "Easily test network connectivity";
  };
}
