{
  buildPerlPackage,
  fetchurl,
  TryTiny,
}:

buildPerlPackage {
  pname = "Test-Fatal";
  version = "0.017";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Test-Fatal-0.017.tar.gz";
    hash = "sha256-N9//2vuEt2Lv6WsC+yqkHzcCbHPmuDWQ23YilpfzxKY=";
  };
  propagatedBuildInputs = [ TryTiny ];
  meta = {
    description = "Incredibly simple helpers for testing code with exceptions";
    homepage = "https://github.com/rjbs/Test-Fatal";
  };
}
