{
  buildPerlModule,
  ExtUtilsHelpers,
  ExtUtilsInstallPaths,
  fetchurl,
  FileShareDir,
}:

buildPerlModule {
  pname = "Module-Build-Tiny";
  version = "0.047";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/Module-Build-Tiny-0.047.tar.gz";
    hash = "sha256-cSYOlCG5PDPdGz59DPFfdZwMp8dT+oQCeew75w+PjJ0=";
  };
  buildInputs = [ FileShareDir ];
  propagatedBuildInputs = [
    ExtUtilsHelpers
    ExtUtilsInstallPaths
  ];
  meta = {
    description = "Tiny replacement for Module::Build";
  };
}
