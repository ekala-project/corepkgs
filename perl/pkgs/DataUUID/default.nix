{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Data-UUID";
  version = "1.226";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Data-UUID-1.226.tar.gz";
    hash = "sha256-CT1X/6DUEalLr6+uSVaX2yb1ydAncZj+P3zyviKZZFM=";
  };
  patches = [
    ./Data-UUID-CVE-2013-4184.patch
  ];
  meta = {
    description = "Globally/Universally Unique Identifiers (GUIDs/UUIDs)";
    license = with lib.licenses; [ bsd0 ];
  };
}
