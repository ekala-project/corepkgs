{
  buildPerlPackage,
  DataOptList,
  fetchurl,
}:

buildPerlPackage {
  pname = "Sub-Exporter";
  version = "0.990";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Sub-Exporter-0.990.tar.gz";
    hash = "sha256-vGTsWgaGX5zGdiFcBqlEizoMizl0/7I6JPjirQkFRPw=";
  };
  propagatedBuildInputs = [ DataOptList ];
  meta = {
    description = "Sophisticated exporter for custom-built routines";
    homepage = "https://github.com/rjbs/Sub-Exporter";
  };
}
