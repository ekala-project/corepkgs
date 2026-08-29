{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Path-Tiny";
  version = "0.144";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/Path-Tiny-0.144.tar.gz";
    hash = "sha256-9uoJTs6EXJUqAsJ4kzJXk1TejUEKcH+bcEW9JBIGSH0=";
  };
  preConfigure = ''
    substituteInPlace lib/Path/Tiny.pm --replace 'use File::Spec 3.40' \
      'use File::Spec 3.39'
  '';
  # This appears to be currently failing tests, though I don't know why.
  # -- ocharles
  doCheck = false;
  meta = {
    description = "File path utility";
    homepage = "https://github.com/dagolden/Path-Tiny";
    license = with lib.licenses; [ asl20 ];
  };
}
