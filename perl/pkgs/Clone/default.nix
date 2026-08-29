{
  BCOW,
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Clone";
  version = "0.46";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GA/GARU/Clone-0.46.tar.gz";
    hash = "sha256-qt7tXkyL1rvfaMDdAGbLUT4Wq55bQ4LcSgqv1ViQaXs=";
  };
  buildInputs = [ BCOW ];
  meta = {
    description = "Recursively copy Perl datatypes";
  };
}
