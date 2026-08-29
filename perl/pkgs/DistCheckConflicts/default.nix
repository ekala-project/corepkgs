{
  buildPerlPackage,
  fetchurl,
  ModuleRuntime,
  TestFatal,
}:

buildPerlPackage {
  pname = "Dist-CheckConflicts";
  version = "0.11";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DO/DOY/Dist-CheckConflicts-0.11.tar.gz";
    hash = "sha256-6oRLlobJTWZtnURDIddkSQss3i+YXEFltMLHdmXK7cQ=";
  };
  buildInputs = [ TestFatal ];
  propagatedBuildInputs = [ ModuleRuntime ];
  meta = {
    description = "Declare version conflicts for your dist";
  };
}
