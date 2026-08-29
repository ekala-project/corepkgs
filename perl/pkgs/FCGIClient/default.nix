{
  buildPerlModule,
  fetchurl,
  ModuleBuildTiny,
  Moo,
  TypeTiny,
}:

buildPerlModule {
  pname = "FCGI-Client";
  version = "0.09";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TOKUHIROM/FCGI-Client-0.09.tar.gz";
    hash = "sha256-1TfLCc5aqz9Eemu0QV5GzAbv4BYRzVYom1WCvbRiIeg=";
  };
  propagatedBuildInputs = [
    Moo
    TypeTiny
  ];
  buildInputs = [ ModuleBuildTiny ];
  meta = {
    description = "Client library for fastcgi protocol";
    homepage = "https://github.com/tokuhirom/p5-fcgi-client";
  };
}
