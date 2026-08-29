{
  buildPerlPackage,
  fetchurl,
  HTTPMessage,
}:

buildPerlPackage {
  pname = "HTTP-Negotiate";
  version = "6.01";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GA/GAAS/HTTP-Negotiate-6.01.tar.gz";
    hash = "sha256-HHKcHqYxAOh4QFzafWb5rf0+1PHWysrKDukVLfco4BY=";
  };
  propagatedBuildInputs = [ HTTPMessage ];
  meta = {
    description = "Choose a variant to serve";
  };
}
