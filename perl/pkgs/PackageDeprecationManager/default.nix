{
  buildPerlPackage,
  fetchurl,
  lib,
  PackageStash,
  ParamsUtil,
  SubInstall,
  SubName,
  TestFatal,
  TestWarnings,
}:

buildPerlPackage {
  pname = "Package-DeprecationManager";
  version = "0.18";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Package-DeprecationManager-0.18.tar.gz";
    hash = "sha256-to0/DO1Vt2Ff3btgKbifkqNP4N2Mb9a87/wVfVaDT+g=";
  };
  buildInputs = [
    TestFatal
    TestWarnings
  ];
  propagatedBuildInputs = [
    PackageStash
    ParamsUtil
    SubInstall
    SubName
  ];
  meta = {
    description = "Manage deprecation warnings for your distribution";
    license = with lib.licenses; [ artistic2 ];
  };
}
