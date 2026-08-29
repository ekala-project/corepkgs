{
  buildPerlPackage,
  fetchurl,
  TestDeep,
}:

buildPerlPackage {
  pname = "CPAN-Meta-Check";
  version = "0.018";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/CPAN-Meta-Check-0.018.tar.gz";
    hash = "sha256-9hnS316g/ZHIz4PrVKzMteQ9nm7Bo/cns9CsFdDPN4o=";
  };
  buildInputs = [ TestDeep ];
  meta = {
    description = "Verify requirements in a CPAN::Meta object";
  };
}
