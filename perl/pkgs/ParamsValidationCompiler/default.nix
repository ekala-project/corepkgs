{
  buildPerlPackage,
  EvalClosure,
  ExceptionClass,
  fetchurl,
  lib,
  Specio,
  Test2PluginNoWarnings,
  Test2Suite,
  TestWithoutModule,
}:

buildPerlPackage {
  pname = "Params-ValidationCompiler";
  version = "0.31";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Params-ValidationCompiler-0.31.tar.gz";
    hash = "sha256-e2SXFz8batsp9dUdjPnsNtLxIZQStLJBDp13qQHoSm0=";
  };
  propagatedBuildInputs = [
    EvalClosure
    ExceptionClass
  ];
  buildInputs = [
    Specio
    Test2PluginNoWarnings
    Test2Suite
    TestWithoutModule
  ];
  meta = {
    description = "Build an optimized subroutine parameter validator once, use it forever";
    license = with lib.licenses; [ artistic2 ];
  };
}
