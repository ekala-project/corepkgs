{
  buildPerlPackage,
  fetchurl,
  IOTty,
}:

buildPerlPackage {
  pname = "Expect";
  version = "1.35";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JA/JACOBY/Expect-1.35.tar.gz";
    hash = "sha256-CdknYUId7NSVhTEDN5FlqZ779FLHIPMCd2As8jZ5/QY=";
  };
  propagatedBuildInputs = [ IOTty ];
  meta = {
    description = "Automate interactions with command line programs that expose a text terminal interface";
  };
}
