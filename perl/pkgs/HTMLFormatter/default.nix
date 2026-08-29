{
  buildPerlPackage,
  fetchurl,
  FileSlurper,
  FontAFM,
  HTMLTree,
  TestWarnings,
}:

buildPerlPackage {
  pname = "HTML-Formatter";
  version = "2.16";
  src = fetchurl {
    url = "mirror://cpan/authors/id/N/NI/NIGELM/HTML-Formatter-2.16.tar.gz";
    hash = "sha256-ywoN2Kpei6nKIUzkUb9N8zqgnBPpB+jTCC3a/rMBUcw=";
  };
  buildInputs = [
    FileSlurper
    TestWarnings
  ];
  propagatedBuildInputs = [
    FontAFM
    HTMLTree
  ];
  meta = {
    description = "Base class for HTML formatters";
  };
}
