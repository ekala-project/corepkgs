{
  buildPerlPackage,
  fetchurl,
  HTTPMessage,
  ModuleBuildTiny,
  TestNeeds,
}:

buildPerlPackage {
  pname = "HTTP-Daemon";
  version = "6.16";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Daemon-6.16.tar.gz";
    hash = "sha256-s40JJyXm+k4MTcKkfhVwcEkbr6Db4Wx4o1joBqp+Fz0=";
  };
  buildInputs = [
    ModuleBuildTiny
    TestNeeds
  ];
  propagatedBuildInputs = [ HTTPMessage ];
  __darwinAllowLocalNetworking = true;
  meta = {
    description = "Simple http server class";
    homepage = "https://github.com/libwww-perl/HTTP-Daemon";
  };
}
