{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Exporter-Tiny";
  version = "1.006002";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TOBYINK/Exporter-Tiny-1.006002.tar.gz";
    hash = "sha256-byleLL/7HbwVvbna3DQWccHgzSvfLTErF1Jic8MiY40=";
  };
  meta = {
    description = "Exporter with the features of Sub::Exporter but only core dependencies";
  };
}
