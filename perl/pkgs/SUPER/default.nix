{
  buildPerlModule,
  fetchurl,
  SubIdentify,
}:

buildPerlModule {
  pname = "SUPER";
  version = "1.20190531";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CH/CHROMATIC/SUPER-1.20190531.tar.gz";
    hash = "sha256-aF0e525/DpAGlCkjv334sRwQcTKZKRdZPc9zl9QX05o=";
  };
  propagatedBuildInputs = [ SubIdentify ];
  meta = {
    description = "Control superclass method dispatch";
  };
}
