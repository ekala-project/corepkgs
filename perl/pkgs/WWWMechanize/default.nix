{
  buildPerlPackage,
  CGI,
  fetchurl,
  HTMLForm,
  HTMLTree,
  HTTPServerSimple,
  LWP,
  PathTiny,
  TestDeep,
  TestFatal,
  TestOutput,
  TestWarnings,
}:

buildPerlPackage {
  pname = "WWW-Mechanize";
  version = "2.17";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SI/SIMBABQUE/WWW-Mechanize-2.17.tar.gz";
    hash = "sha256-nAIAPoRiHeoSyYDEEB555PjK5OOCzT2iOfqovRmPBjo=";
  };
  propagatedBuildInputs = [
    HTMLForm
    HTMLTree
    LWP
  ];
  doCheck = false;
  buildInputs = [
    CGI
    HTTPServerSimple
    PathTiny
    TestDeep
    TestFatal
    TestOutput
    TestWarnings
  ];
  meta = {
    description = "Handy web browsing in a Perl object";
    homepage = "https://github.com/libwww-perl/WWW-Mechanize";
    mainProgram = "mech-dump";
  };
}
