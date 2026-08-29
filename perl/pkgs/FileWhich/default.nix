{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "File-Which";
  version = "1.27";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PL/PLICEASE/File-Which-1.27.tar.gz";
    hash = "sha256-MgHxpg4/FkhAguYEXIloQiYfw0Xen7LmIP0qLHrzqTo=";
  };
  meta = {
    description = "Perl implementation of the which utility as an API";
  };
}
