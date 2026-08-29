{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Test-Simple";
  version = "1.302195";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Test-Simple-1.302195.tar.gz";
    hash = "sha256-s5C7I1kuC5Rsla27PDCxG8Y0ooayhHvmEa2SnFfjmmw=";
  };
  meta = {
    description = "Basic utilities for writing tests";
  };
}
