{
  buildPerlPackage,
  CompressBzip2,
  DataCompare,
  fetchurl,
  ModuleSignature,
}:

buildPerlPackage {
  pname = "CPAN-Checksums";
  version = "2.14";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AN/ANDK/CPAN-Checksums-2.14.tar.gz";
    hash = "sha256-QIBxbF2n4DtQTjzA6h/V757WkV9vtzdWTp4T01Wonjk=";
  };
  propagatedBuildInputs = [
    CompressBzip2
    DataCompare
    ModuleSignature
  ];
  meta = {
    description = "Write a CHECKSUMS file for a directory as on CPAN";
  };
}
