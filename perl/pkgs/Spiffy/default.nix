{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Spiffy";
  version = "0.46";
  src = fetchurl {
    url = "mirror://cpan/authors/id/I/IN/INGY/Spiffy-0.46.tar.gz";
    hash = "sha256-j1hiCoQgJVxJtsQ8X/WAK9JeTwkkDFHlvysCKDPUHaM=";
  };
  meta = {
    description = "Spiffy Perl Interface Framework For You";
  };
}
