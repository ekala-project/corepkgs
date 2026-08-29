{
  buildPerlPackage,
  fetchurl,
  SubUplevel,
}:

buildPerlPackage {
  pname = "Test-Warn";
  version = "0.37";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BI/BIGJ/Test-Warn-0.37.tar.gz";
    hash = "sha256-mMoy5/L16om4v7mgYJl389FT4kLi5RcFEmy5VPGga1c=";
  };
  propagatedBuildInputs = [ SubUplevel ];
  meta = {
    description = "Perl extension to test methods for warnings";
  };
}
