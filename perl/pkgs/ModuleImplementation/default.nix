{
  buildPerlPackage,
  fetchurl,
  lib,
  ModuleRuntime,
  TestFatal,
  TestRequires,
  TryTiny,
}:

buildPerlPackage {
  pname = "Module-Implementation";
  version = "0.09";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Module-Implementation-0.09.tar.gz";
    hash = "sha256-wV8aEvDCEwye//PC4a/liHsIzNAzvRMhhtHn1Qh/1m0=";
  };
  buildInputs = [
    TestFatal
    TestRequires
  ];
  propagatedBuildInputs = [
    ModuleRuntime
    TryTiny
  ];
  meta = {
    description = "Loads one of several alternate underlying implementations for a module";
    license = with lib.licenses; [ artistic2 ];
  };
}
