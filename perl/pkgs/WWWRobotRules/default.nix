{
  buildPerlPackage,
  fetchurl,
  URI,
}:

buildPerlPackage {
  pname = "WWW-RobotRules";
  version = "6.02";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GA/GAAS/WWW-RobotRules-6.02.tar.gz";
    hash = "sha256-RrUC56KI1VlCmJHutdl5Rh3T7MalxJHq2F0WW24DpR4=";
  };
  propagatedBuildInputs = [ URI ];
  meta = {
    description = "Database of robots.txt-derived permissions";
  };
}
