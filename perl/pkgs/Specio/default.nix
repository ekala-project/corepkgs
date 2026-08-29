{
  buildPerlPackage,
  DevelStackTrace,
  EvalClosure,
  fetchurl,
  lib,
  ModuleRuntime,
  MROCompat,
  RoleTiny,
  SubQuote,
  TestFatal,
  TestNeeds,
  TryTiny,
}:

buildPerlPackage {
  pname = "Specio";
  version = "0.48";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Specio-0.48.tar.gz";
    hash = "sha256-DIV5NYDxJ07wgXMHkTHRAfd7IqzOp6+oJVIC8IEWgrI=";
  };
  propagatedBuildInputs = [
    DevelStackTrace
    EvalClosure
    MROCompat
    ModuleRuntime
    RoleTiny
    SubQuote
    TryTiny
  ];
  buildInputs = [
    TestFatal
    TestNeeds
  ];
  meta = {
    description = "Type constraints and coercions for Perl";
    license = with lib.licenses; [ artistic2 ];
  };
}
