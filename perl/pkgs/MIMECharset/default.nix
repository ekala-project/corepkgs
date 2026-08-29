{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "MIME-Charset";
  version = "1.013.1";
  src = fetchurl {
    url = "mirror://cpan/authors/id/N/NE/NEZUMI/MIME-Charset-1.013.1.tar.gz";
    hash = "sha256-G7em4MDSUfI9bmC/hMmt78W3TuxYR1v+5NORB+YIcPA=";
  };
  meta = {
    description = "Charset Information for MIME";
  };
}
