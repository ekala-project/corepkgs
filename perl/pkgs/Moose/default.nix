{
  buildPerlPackage,
  ClassLoadXS,
  CPANMetaCheck,
  DataOptList,
  DevelGlobalDestruction,
  DevelOverloadInfo,
  DevelStackTrace,
  DistCheckConflicts,
  EvalClosure,
  fetchurl,
  ModuleRuntimeConflicts,
  MROCompat,
  PackageDeprecationManager,
  PackageStashXS,
  ParamsUtil,
  SubExporter,
  TestCleanNamespaces,
  TestFatal,
  TestNeeds,
  TestRequires,
  TryTiny,
}:

buildPerlPackage {
  pname = "Moose";
  version = "2.2206";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Moose-2.2206.tar.gz";
    hash = "sha256-Z5csTivDn72jhRgXevDme7vrVIVi5OxLdZoaelg+UFs=";
  };
  buildInputs = [
    DistCheckConflicts
    CPANMetaCheck
    TestCleanNamespaces
    TestFatal
    TestNeeds
    TestRequires
  ];
  propagatedBuildInputs = [
    ClassLoadXS
    DataOptList
    DevelGlobalDestruction
    DevelOverloadInfo
    DevelStackTrace
    EvalClosure
    MROCompat
    ModuleRuntimeConflicts
    PackageDeprecationManager
    PackageStashXS
    ParamsUtil
    SubExporter
    TryTiny
  ];
  meta = {
    description = "Postmodern object system for Perl 5";
    homepage = "http://moose.perl.org";

    mainProgram = "moose-outdated";
  };
}
