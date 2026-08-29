{
  buildPerlPackage,
  fetchurl,
  Filepushd,
  Moo,
  Mouse,
  namespaceclean,
  PackageStash,
  RoleTiny,
  SubExporter,
  SubIdentify,
  TestDeep,
  TestNeeds,
  TestWarnings,
}:

buildPerlPackage {
  pname = "Test-CleanNamespaces";
  version = "0.24";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Test-CleanNamespaces-0.24.tar.gz";
    hash = "sha256-M41VaejommVJNfhD7AvISqpIb+jdGJj7nKs+zOzVMno=";
  };
  buildInputs = [
    Filepushd
    Moo
    Mouse
    RoleTiny
    SubExporter
    TestDeep
    TestNeeds
    TestWarnings
    namespaceclean
  ];
  propagatedBuildInputs = [
    PackageStash
    SubIdentify
  ];
  meta = {
    description = "Check for uncleaned imports";
    homepage = "https://github.com/karenetheridge/Test-CleanNamespaces";
  };
}
