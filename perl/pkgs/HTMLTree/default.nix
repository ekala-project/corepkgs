{
  buildPerlModule,
  fetchurl,
  HTMLParser,
  TestFatal,
}:

buildPerlModule {
  pname = "HTML-Tree";
  version = "5.07";
  src = fetchurl {
    url = "mirror://cpan/authors/id/K/KE/KENTNL/HTML-Tree-5.07.tar.gz";
    hash = "sha256-8DdNuEcxwgS4bB1bkJdf7w0wqGvZ3vkZND5VTjGp278=";
  };
  buildInputs = [ TestFatal ];
  propagatedBuildInputs = [ HTMLParser ];
  meta = {
    description = "Work with HTML in a DOM-like tree structure";
    mainProgram = "htmltree";
  };
}
