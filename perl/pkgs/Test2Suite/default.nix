{
  buildPerlPackage,
  fetchurl,
  ModulePluggable,
  ScopeGuard,
  SubInfo,
  TermTable,
  TestSimple13,
}:

buildPerlPackage {
  pname = "Test2-Suite";
  version = "0.000156";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Suite-0.000156.tar.gz";
    hash = "sha256-vzgq5y86k79+02iFEY+uL/qw/xF3Q/WQON8lTv7yyU4=";
  };
  propagatedBuildInputs = [
    ModulePluggable
    ScopeGuard
    SubInfo
    TermTable
    TestSimple13
  ];
  meta = {
    description = "Distribution with a rich set of tools built upon the Test2 framework";
  };
}
