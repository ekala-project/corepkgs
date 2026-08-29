{
  buildPerlPackage,
  fetchurl,
  Test2Suite,
}:

buildPerlPackage {
  pname = "Test2-Plugin-MemUsage";
  version = "0.002003";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Plugin-MemUsage-0.002003.tar.gz";
    hash = "sha256-XgZi1agjrggWQfXOgoQxEe7BgxzTH4g6bG3lSv34fCU=";
  };
  buildInputs = [ Test2Suite ];
  meta = {
    description = "Collect and display memory usage information";
  };
}
