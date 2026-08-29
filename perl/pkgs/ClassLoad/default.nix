{
  buildPerlPackage,
  DataOptList,
  fetchurl,
  PackageStash,
  TestFatal,
  TestNeeds,
}:

buildPerlPackage {
  pname = "Class-Load";
  version = "0.25";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Class-Load-0.25.tar.gz";
    hash = "sha256-Kkj6d5tSl+VhVjgOizJjfGxY3stPSn88c1BSPhEnX48=";
  };
  buildInputs = [
    TestFatal
    TestNeeds
  ];
  propagatedBuildInputs = [
    DataOptList
    PackageStash
  ];
  meta = {
    description = "Working (require \"Class::Name\") and more";
    homepage = "https://github.com/moose/Class-Load";
  };
}
