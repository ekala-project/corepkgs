{
  buildPerlPackage,
  ClassMethodModifiers,
  fetchurl,
  ModuleRuntime,
  RoleTiny,
  SubQuote,
  TestFatal,
}:

buildPerlPackage {
  pname = "Moo";
  version = "2.005005";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HA/HAARG/Moo-2.005005.tar.gz";
    hash = "sha256-+1opUmSfrtBzc/Igt4AEqcaro4dzkTN0DBdw6bH0sQg=";
  };
  buildInputs = [ TestFatal ];
  propagatedBuildInputs = [
    ClassMethodModifiers
    ModuleRuntime
    RoleTiny
    SubQuote
  ];
  meta = {
    description = "Minimalist Object Orientation (with Moose compatibility)";
  };
}
