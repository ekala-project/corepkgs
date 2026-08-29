{
  buildPerlPackage,
  ExtUtilsConfig,
  fetchurl,
}:

buildPerlPackage {
  pname = "ExtUtils-InstallPaths";
  version = "0.012";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/ExtUtils-InstallPaths-0.012.tar.gz";
    hash = "sha256-hHNeMDe6sf3/o8JQhWetQSp4XJFZnbPBJZOlCh3UNO0=";
  };
  propagatedBuildInputs = [ ExtUtilsConfig ];
  meta = {
    description = "Build.PL install path logic made easy";
  };
}
