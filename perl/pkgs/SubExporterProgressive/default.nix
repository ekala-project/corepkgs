{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Sub-Exporter-Progressive";
  version = "0.001013";
  src = fetchurl {
    url = "mirror://cpan/authors/id/F/FR/FREW/Sub-Exporter-Progressive-0.001013.tar.gz";
    hash = "sha256-1TW3lU1k2hrBMFsfrfmCAnaeNZk3aFSyztkMOCvqwFY=";
  };
  meta = {
    description = "Only use Sub::Exporter if you need it";
    homepage = "https://github.com/frioux/Sub-Exporter-Progressive";
  };
}
