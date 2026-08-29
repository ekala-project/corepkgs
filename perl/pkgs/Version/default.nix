{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "version";
  version = "0.9930";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/version-0.9930.tar.gz";
    hash = "sha256-YduVX7yzn1kC+myLlXrrJ0HiPUhA+Eq/hGrx9nCu7jA=";
  };
  meta = {
    description = "Structured version objects";
  };
}
