{
  buildPerlPackage,
  fetchurl,
  lib,
  MozillaCA,
  NetSSLeay,
}:

buildPerlPackage {
  pname = "IO-Socket-SSL";
  version = "2.083";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SU/SULLR/IO-Socket-SSL-2.083.tar.gz";
    hash = "sha256-kE7yh2VECpfYqaDfWX+MPX88sKBT0bCCwQvtA7yAIGk=";
  };
  propagatedBuildInputs = [
    MozillaCA
    NetSSLeay
  ];
  # Fix path to default certificate store.
  postPatch = ''
    substituteInPlace lib/IO/Socket/SSL.pm \
      --replace "\$openssldir/cert.pem" "/etc/ssl/certs/ca-certificates.crt"
  '';
  doCheck = false; # tries to connect to facebook.com etc.
  meta = {
    description = "Nearly transparent SSL encapsulation for IO::Socket::INET";
    homepage = "https://github.com/noxxi/p5-io-socket-ssl";
  };
}
