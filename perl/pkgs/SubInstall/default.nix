{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Sub-Install";
  version = "0.929";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Sub-Install-0.929.tar.gz";
    hash = "sha256-gLHigdjNOysx2scR9cihZXqHzYC75przkkvL605dsHc=";
  };
  meta = {
    description = "Install subroutines into packages easily";
    homepage = "https://github.com/rjbs/Sub-Install";
  };
}
