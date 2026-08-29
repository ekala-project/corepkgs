{
  buildPerlModule,
  fetchurl,
}:

buildPerlModule {
  pname = "HTML-TagCloud";
  version = "0.38";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RO/ROBERTSD/HTML-TagCloud-0.38.tar.gz";
    hash = "sha256-SYCZRy3vhmtEi/YvQYLfrfWUcuE/JMuGZKZxynm2cBU=";
  };
  meta = {
    description = "Generate An HTML Tag Cloud";
  };
}
