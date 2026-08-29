{
  buildPerlPackage,
  fetchurl,
  TestBase,
  TestDeep,
  TestYAML,
}:

buildPerlPackage {
  pname = "YAML";
  version = "1.30";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TI/TINITA/YAML-1.30.tar.gz";
    hash = "sha256-UDCm1sv/rxJYMFC/VSqoANRkbKlnjBh63WSSJ/V0ec0=";
  };

  buildInputs = [
    TestBase
    TestDeep
    TestYAML
  ];

  meta = {
    description = "YAML Ain't Markup Language (tm)";
    homepage = "https://github.com/ingydotnet/yaml-pm";
  };
}
