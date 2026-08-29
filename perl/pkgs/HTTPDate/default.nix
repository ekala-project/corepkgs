{
  buildPerlPackage,
  fetchurl,
  TimeDate,
}:

buildPerlPackage {
  pname = "HTTP-Date";
  version = "6.06";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Date-6.06.tar.gz";
    hash = "sha256-e2hRkcasw+dz0fwCyV7h+frpT3d4MXX154wYHMktK1I=";
  };
  propagatedBuildInputs = [ TimeDate ];
  meta = {
    description = "Date conversion routines";
    homepage = "https://github.com/libwww-perl/HTTP-Date";
  };
}
