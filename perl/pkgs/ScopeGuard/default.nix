{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Scope-Guard";
  version = "0.21";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CH/CHOCOLATE/Scope-Guard-0.21.tar.gz";
    hash = "sha256-jJsb6lxWRI4sP63GXQW+nkaQo4I6gPOdLxD92Pd30ng=";
  };
  meta = {
    description = "Lexically-scoped resource management";
  };
}
