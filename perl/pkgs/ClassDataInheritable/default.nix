{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Class-Data-Inheritable";
  version = "0.09";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RS/RSHERER/Class-Data-Inheritable-0.09.tar.gz";
    hash = "sha256-RAiNbpBxLhh7ilsFDKWxxw7+K6oyrhI+m9j1nynwbk0=";
  };
  meta = {
    description = "Inheritable, overridable class data";
  };
}
