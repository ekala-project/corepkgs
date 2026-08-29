{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Class-Inspector";
  version = "1.36";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PL/PLICEASE/Class-Inspector-1.36.tar.gz";
    hash = "sha256-zCldI6RyaHwkSJ1YIm6tI7n9wliOUi8LXwdHdBcAaU4=";
  };
  meta = {
    description = "Get information about a class and its structure";
  };
}
