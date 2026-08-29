{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "FCGI-ProcManager";
  version = "0.28";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AR/ARODLAND/FCGI-ProcManager-0.28.tar.gz";
    hash = "sha256-4clYwEJCehdeBR4ACPICXo7IBhPTx3UFl7+OUpsEQg4=";
  };
  meta = {
    description = "Perl-based FastCGI process manager";
    license = with lib.licenses; [ gpl2Plus ];
  };
}
