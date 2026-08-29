{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Test-Needs";
  version = "0.002010";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HA/HAARG/Test-Needs-0.002010.tar.gz";
    hash = "sha256-kj/9x4/LqWYJdT5LriawugGGiT3kpjzVI24BLHyQ4gg=";
  };
  meta = {
    description = "Skip tests when modules not available";
  };
}
