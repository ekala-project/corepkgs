{
  buildPerlPackage,
  fetchurl,
  FileWhich,
  stdenv,
}:

buildPerlPackage {
  pname = "File-HomeDir";
  version = "1.006";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RE/REHSACK/File-HomeDir-1.006.tar.gz";
    hash = "sha256-WTc3xi3w9tq11BIuC0R2QXlFu2Jiwz7twAlmXvFUiFI=";
  };
  propagatedBuildInputs = [ FileWhich ];
  preCheck = "export HOME=$TMPDIR";
  doCheck = !stdenv.hostPlatform.isDarwin;
  meta = {
    description = "Find your home and other directories on any platform";
  };
}
