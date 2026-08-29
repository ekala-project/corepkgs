{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "IO";
  version = "1.51";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TODDR/IO-1.51.tar.gz";
    hash = "sha256-VJPqVZmHKM0rfsuCNMWPtdXfJwmNDwet3KIkRNdhbOA=";
  };
  doCheck = false;
  meta = {
    description = "Perl core IO modules";
  };
}
