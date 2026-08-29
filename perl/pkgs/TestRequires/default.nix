{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Test-Requires";
  version = "0.11";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TOKUHIROM/Test-Requires-0.11.tar.gz";
    hash = "sha256-S4jeVJWX7s3ffDw4pNAgShb1mtgEV3tnGJasBOJOBA8=";
  };
  meta = {
    description = "Checks to see if the module can be loaded";
    homepage = "https://github.com/tokuhirom/Test-Requires";
  };
}
