{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Crypt-RC4";
  version = "2.02";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SI/SIFUKURT/Crypt-RC4-2.02.tar.gz";
    hash = "sha256-XsRCXGvCIgeIljC+c1DZlobmKkTGE2lgEQIDzVlK4Oo=";
  };
  meta = {
    description = "Perl implementation of the RC4 encryption algorithm";
  };
}
