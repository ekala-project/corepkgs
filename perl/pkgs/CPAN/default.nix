{
  ArchiveZip,
  buildPerlPackage,
  CompressBzip2,
  CPANChecksums,
  CPANPerlReleases,
  Expect,
  fetchurl,
  FileHomeDir,
  FileWhich,
  IOSocketSSL,
  LogLog4perl,
  LWP,
  ModuleSignature,
  TermReadKey,
  TextGlob,
  YAML,
  YAMLLibYAML,
  YAMLSyck,
}:

buildPerlPackage {
  pname = "CPAN";
  version = "2.36";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AN/ANDK/CPAN-2.36.tar.gz";
    hash = "sha256-HXKl60DliOPBDx88hckC6HGxaDdH1ncjOvd3yCv8kJ4=";
  };
  propagatedBuildInputs = [
    ArchiveZip
    CPANChecksums
    CPANPerlReleases
    CompressBzip2
    Expect
    FileHomeDir
    FileWhich
    LWP
    LogLog4perl
    ModuleSignature
    TermReadKey
    TextGlob
    YAML
    YAMLLibYAML
    YAMLSyck
    IOSocketSSL
  ];
  meta = {
    description = "Query, download and build perl modules from CPAN sites";
    mainProgram = "cpan";
  };
}
