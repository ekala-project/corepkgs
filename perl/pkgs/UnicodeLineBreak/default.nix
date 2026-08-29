{
  buildPerlPackage,
  fetchurl,
  MIMECharset,
}:

buildPerlPackage {
  pname = "Unicode-LineBreak";
  version = "2019.001";
  src = fetchurl {
    url = "mirror://cpan/authors/id/N/NE/NEZUMI/Unicode-LineBreak-2019.001.tar.gz";
    hash = "sha256-SGdi5MrN3Md7E5ifl5oCn4RjC4F15/7xeYnhV9S2MYo=";
  };
  propagatedBuildInputs = [ MIMECharset ];
  meta = {
    description = "UAX #14 Unicode Line Breaking Algorithm";
  };
}
