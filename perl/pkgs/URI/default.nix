{
  buildPerlPackage,
  fetchurl,
  TestFatal,
  TestNeeds,
  TestWarnings,
}:

buildPerlPackage {
  pname = "URI";
  version = "5.21";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/URI-5.21.tar.gz";
    hash = "sha256-liZYYM1hveFuhBXc+/EIBW3hYsqgrDf4HraVydLgq3c=";
  };
  buildInputs = [
    TestFatal
    TestNeeds
    TestWarnings
  ];
  meta = {
    description = "Uniform Resource Identifiers (absolute and relative)";
    homepage = "https://github.com/libwww-perl/URI";
  };
}
