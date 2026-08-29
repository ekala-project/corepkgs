{
  buildPerlPackage,
  fetchurl,
  lib,
  openssl,
  zlib,
}:

buildPerlPackage {
  pname = "Net-SSLeay";
  version = "1.92";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CH/CHRISN/Net-SSLeay-1.92.tar.gz";
    hash = "sha256-R8LyswDy5xYtcdaZ9jPdajWwYloAy9qMUKwBFEqTlqk=";
  };
  buildInputs = [
    openssl
    zlib
  ];
  doCheck = false; # Test performs network access.
  preConfigure = ''
    mkdir openssl
    ln -s ${lib.getLib openssl}/lib openssl
    ln -s ${openssl.bin}/bin openssl
    ln -s ${openssl.dev}/include openssl
    export OPENSSL_PREFIX=$(realpath openssl)
  '';
  meta = {
    description = "Perl bindings for OpenSSL and LibreSSL";
    license = with lib.licenses; [ artistic2 ];
  };
}
