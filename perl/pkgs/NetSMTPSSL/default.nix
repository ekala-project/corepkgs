{
  buildPerlPackage,
  fetchurl,
  IOSocketSSL,
}:

buildPerlPackage {
  pname = "Net-SMTP-SSL";
  version = "1.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Net-SMTP-SSL-1.04.tar.gz";
    hash = "sha256-eynEWt0Z09UIS3Ufe6iajkBHmkRs4hz9nMdB5VgzKgA=";
  };
  propagatedBuildInputs = [ IOSocketSSL ];
  meta = {
    description = "SSL support for Net::SMTP";
  };
}
