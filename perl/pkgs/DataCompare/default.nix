{
  buildPerlPackage,
  Clone,
  fetchurl,
  FileFindRule,
}:

buildPerlPackage {
  pname = "Data-Compare";
  version = "1.29";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DC/DCANTRELL/Data-Compare-1.29.tar.gz";
    hash = "sha256-U8nbO5MmPIiqo8QHLYGere0CTXo2s4wMN3N9KI1a+ow=";
  };
  propagatedBuildInputs = [
    Clone
    FileFindRule
  ];
  meta = {
    description = "Compare perl data structures";
  };
}
