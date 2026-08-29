{
  buildPerlPackage,
  fetchurl,
  IOSocketSSL,
  LWP,
  TestNeeds,
  TestRequiresInternet,
}:

buildPerlPackage {
  pname = "LWP-Protocol-https";
  version = "6.11";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/LWP-Protocol-https-6.11.tar.gz";
    hash = "sha256-ATLdvwNmFWXKhQUPKlCU+5Jjy7w8yxpNnEGsm7CDuRc=";
  };
  patches = [ ./lwp-protocol-https-cert-file.patch ];
  propagatedBuildInputs = [
    IOSocketSSL
    LWP
  ];
  buildInputs = [
    TestRequiresInternet
    TestNeeds
  ];
  meta = {
    description = "Provide https support for LWP::UserAgent";
    homepage = "https://github.com/libwww-perl/LWP-Protocol-https";
  };
}
