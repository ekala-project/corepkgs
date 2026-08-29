{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "CPAN-Perl-Releases";
  version = "5.20230920";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BI/BINGOS/CPAN-Perl-Releases-5.20230920.tar.gz";
    hash = "sha256-MbyTiJR2uOx1iRjdmSSmKYPgh7BsjN6Sb7mnp+h60cA=";
  };
  meta = {
    description = "Mapping Perl releases on CPAN to the location of the tarballs";
    homepage = "https://github.com/bingos/cpan-perl-releases";
  };
}
