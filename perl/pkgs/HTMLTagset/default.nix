{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "HTML-Tagset";
  version = "3.20";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PETDANCE/HTML-Tagset-3.20.tar.gz";
    hash = "sha256-rbF9rJ42zQEfUkOIHJc5QX/RAvznYPjeTpvkxxMRCOI=";
  };
  meta = {
    description = "Data tables useful in parsing HTML";
  };
}
