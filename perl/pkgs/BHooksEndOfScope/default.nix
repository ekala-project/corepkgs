{
  buildPerlPackage,
  fetchurl,
  ModuleImplementation,
  SubExporterProgressive,
}:

buildPerlPackage {
  pname = "B-Hooks-EndOfScope";
  version = "0.26";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/B-Hooks-EndOfScope-0.26.tar.gz";
    hash = "sha256-Od8vjAB6dUZyB1+VuQeXuuvpetptlEsZemNScJyzBnE=";
  };
  propagatedBuildInputs = [
    ModuleImplementation
    SubExporterProgressive
  ];
  meta = {
    description = "Execute code after a scope finished compilation";
    homepage = "https://github.com/karenetheridge/B-Hooks-EndOfScope";
  };
}
