{
  BC,
  buildPerlPackage,
  DevelCheckBin,
  fetchurl,
}:

buildPerlPackage {
  pname = "Sub-Name";
  version = "0.27";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Sub-Name-0.27.tar.gz";
    hash = "sha256-7PNvuhxHypPh2qOUlo7TnEGGhnRZ2c0XPEIeK5cgQ+g=";
  };
  buildInputs = [
    BC
    DevelCheckBin
  ];
  meta = {
    description = "(Re)name a sub";
    homepage = "https://github.com/p5sagit/Sub-Name";
  };
}
