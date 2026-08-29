{
  buildPerlPackage,
  fetchurl,
  TestFatal,
}:

buildPerlPackage {
  pname = "LWP-MediaTypes";
  version = "6.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/LWP-MediaTypes-6.04.tar.gz";
    hash = "sha256-jxvKEtqxahwqfAOknF5YzOQab+yVGfCq37qNrZl5Gdk=";
  };
  buildInputs = [ TestFatal ];
  meta = {
    description = "Guess media type for a file or a URL";
    homepage = "https://github.com/libwww-perl/lwp-mediatypes";
  };
}
