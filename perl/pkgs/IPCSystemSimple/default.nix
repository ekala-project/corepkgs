{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "IPC-System-Simple";
  version = "1.30";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JK/JKEENAN/IPC-System-Simple-1.30.tar.gz";
    hash = "sha256-Iub1IitQXuUTBY/co1q3oeq4BTm5jlykqSOnCorpup4=";
  };
  meta = {
    description = "Run commands simply, with detailed diagnostics";
    homepage = "http://thenceforward.net/perl/modules/IPC-System-Simple";
  };
}
