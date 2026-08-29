{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Log-Log4perl";
  version = "1.57";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETJ/Log-Log4perl-1.57.tar.gz";
    hash = "sha256-D4/Ldjio89tMeX35T9vFYBN0kULy+Uy8lbQ8n8oJahM=";
  };
  meta = {
    description = "Log4j implementation for Perl";
    homepage = "https://mschilli.github.io/log4perl/";
    mainProgram = "l4p-tmpl";
  };
}
