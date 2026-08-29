{
  buildPerlPackage,
  fetchurl,
  TestFatal,
  TestNeeds,
}:

buildPerlPackage {
  pname = "Package-Stash-XS";
  version = "0.30";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Package-Stash-XS-0.30.tar.gz";
    hash = "sha256-JrrWXBlZxXN5s+E53HdvvsX3ApBmF+8nzcKT3fEjkjE=";
  };
  buildInputs = [
    TestFatal
    TestNeeds
  ];
  meta = {
    description = "Faster and more correct implementation of the Package::Stash API";
    homepage = "https://github.com/moose/Package-Stash-XS";
  };
}
