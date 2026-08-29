{
  buildPerlPackage,
  fetchurl,
  TestFatal,
  TestNeeds,
}:

buildPerlPackage {
  pname = "Class-Method-Modifiers";
  version = "2.15";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Class-Method-Modifiers-2.15.tar.gz";
    hash = "sha256-Zc2Fv+R10GbpGG96jMY2BwmFswsOuxzehoHPBiwuFfw=";
  };
  buildInputs = [
    TestFatal
    TestNeeds
  ];
  meta = {
    description = "Provides Moose-like method modifiers";
    homepage = "https://github.com/moose/Class-Method-Modifiers";
  };
}
