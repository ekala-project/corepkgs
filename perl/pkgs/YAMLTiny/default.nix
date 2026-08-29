{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "YAML-Tiny";
  version = "1.74";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/YAML-Tiny-1.74.tar.gz";
    hash = "sha256-ezjKn1084kIwpri9wfR/Wy2zSOf3+WZsJvWVVjbjPWw=";
  };
  meta = {
    description = "Read/Write YAML files with as little code as possible";
  };
}
