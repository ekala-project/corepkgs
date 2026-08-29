{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Devel-StackTrace";
  version = "2.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Devel-StackTrace-2.04.tar.gz";
    hash = "sha256-zTwD7VR9PULGH6WBTJgpYTk5LnlxwJLgmkMfLJ9daFU=";
  };
  meta = {
    description = "Object representing a stack trace";
    license = with lib.licenses; [ artistic2 ];
  };
}
