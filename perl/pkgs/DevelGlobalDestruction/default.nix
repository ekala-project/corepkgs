{
  buildPerlPackage,
  fetchurl,
  SubExporterProgressive,
}:

buildPerlPackage {
  pname = "Devel-GlobalDestruction";
  version = "0.14";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HA/HAARG/Devel-GlobalDestruction-0.14.tar.gz";
    hash = "sha256-NLil8pmRMRRo/mkTytq6df1dKws+47tB/ltT76uRVKs=";
  };
  propagatedBuildInputs = [ SubExporterProgressive ];
  meta = {
    description = "Provides function returning the equivalent of \${^GLOBAL_PHASE} eq 'DESTRUCT' for older perls";
  };
}
