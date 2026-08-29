{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Test-NoWarnings";
  version = "1.06";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HA/HAARG/Test-NoWarnings-1.06.tar.gz";
    hash = "sha256-wtxRFDt+tjIxIQ4n3yDSyDk3cuCjM1R+yLeiBe1i9zc=";
  };
  meta = {
    description = "Make sure you didn't emit any warnings while testing";
    license = with lib.licenses; [ lgpl21Only ];
  };
}
