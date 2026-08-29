{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Test-File";
  version = "1.993";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BD/BDFOY/Test-File-1.993.tar.gz";
    hash = "sha256-7y/+Gq7HtC2HStQR7GR1R7m5vC9fuT5J4zmUiEVq/Ho=";
  };
  meta = {
    description = "Test file attributes";
    homepage = "https://github.com/briandfoy/test-file";
    license = with lib.licenses; [ artistic2 ];
  };
}
