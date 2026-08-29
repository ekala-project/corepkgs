{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Test-Without-Module";
  version = "0.21";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CO/CORION/Test-Without-Module-0.21.tar.gz";
    hash = "sha256-PN6vraxIU+vq/miTRtVV2l36PPqdTITj5ee/7lC+7EY=";
  };
  meta = {
    description = "Test fallback behaviour in absence of modules";
  };
}
