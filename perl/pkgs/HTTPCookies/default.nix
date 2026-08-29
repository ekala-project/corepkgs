{
  buildPerlPackage,
  fetchurl,
  HTTPMessage,
}:

buildPerlPackage {
  pname = "HTTP-Cookies";
  version = "6.10";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Cookies-6.10.tar.gz";
    hash = "sha256-4282Yzxc5rXkuHb/z3R4fMXv4HNt1/SHvdc8FPC9cAc=";
  };
  propagatedBuildInputs = [ HTTPMessage ];
  meta = {
    description = "HTTP cookie jars";
    homepage = "https://github.com/libwww-perl/HTTP-Cookies";
  };
}
