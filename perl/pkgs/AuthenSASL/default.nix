{
  buildPerlPackage,
  CryptURandom,
  DigestHMAC,
  fetchurl,
}:

buildPerlPackage {
  pname = "Authen-SASL";
  version = "2.1900";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EH/EHUELS/Authen-SASL-2.1900.tar.gz";
    hash = "sha256-vjUzpokbLmdxULR5waDUvxHIu+6+0+e466NAU+k5I7A=";
  };
  propagatedBuildInputs = [
    CryptURandom
    DigestHMAC
  ];
  meta = {
    description = "SASL Authentication framework";
  };
}
