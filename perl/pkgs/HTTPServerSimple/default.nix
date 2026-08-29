{
  buildPerlPackage,
  CGI,
  fetchurl,
}:

buildPerlPackage {
  pname = "HTTP-Server-Simple";
  version = "0.52";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BP/BPS/HTTP-Server-Simple-0.52.tar.gz";
    hash = "sha256-2JOfpPEr1rjAQ1N/0L+WsFWsNoa5zdn6dz3KauZ5y0w=";
  };
  doCheck = false;
  propagatedBuildInputs = [ CGI ];
  meta = {
    description = "Lightweight HTTP server";
  };
}
