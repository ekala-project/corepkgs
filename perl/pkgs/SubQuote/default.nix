{
  buildPerlPackage,
  fetchurl,
  TestFatal,
}:

buildPerlPackage {
  pname = "Sub-Quote";
  version = "2.006008";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HA/HAARG/Sub-Quote-2.006008.tar.gz";
    hash = "sha256-lL69UAr1V2LoPqLyvFlNh6+CgHI3DHEQxgwjioANFbI=";
  };
  buildInputs = [ TestFatal ];
  meta = {
    description = "Efficient generation of subroutines via string eval";
  };
}
