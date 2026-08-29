{
  buildPerlPackage,
  fetchurl,
  SubUplevel,
}:

buildPerlPackage {
  pname = "Test-Exception";
  version = "0.43";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Test-Exception-0.43.tar.gz";
    hash = "sha256-FWsT8Hdk92bYtFpDco8kOa+Bo1EmJUON6reDt4g+tTM=";
  };
  propagatedBuildInputs = [ SubUplevel ];
  meta = {
    description = "Test exception-based code";
  };
}
