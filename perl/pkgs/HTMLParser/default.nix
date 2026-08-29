{
  buildPerlPackage,
  fetchurl,
  HTMLTagset,
  HTTPMessage,
}:

buildPerlPackage {
  pname = "HTML-Parser";
  version = "3.81";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/HTML-Parser-3.81.tar.gz";
    hash = "sha256-wJEKXI+S+IF+3QbM/SJLocLr6MEPVR8DJYeh/IPWL/I=";
  };
  propagatedBuildInputs = [
    HTMLTagset
    HTTPMessage
  ];
  meta = {
    description = "HTML parser class";
    homepage = "https://github.com/libwww-perl/HTML-Parser";
  };
}
