{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "PadWalker";
  version = "2.5";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RO/ROBIN/PadWalker-2.5.tar.gz";
    hash = "sha256-B7Jqu4QRRq8yByqNaMuQF2/7F2/ZJo5vL30Qb4F6DNA=";
  };
  meta = {
    description = "Play with other peoples' lexical variables";
  };
}
