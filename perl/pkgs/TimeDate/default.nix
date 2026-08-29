{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "TimeDate";
  version = "2.33";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AT/ATOOMIC/TimeDate-2.33.tar.gz";
    hash = "sha256-wLacSwOd5vUBsNnxPsWMhrBAwffpsn7ySWUcFD1gXrI=";
  };
  meta = {
    description = "Miscellaneous timezone manipulations routines";
  };
}
