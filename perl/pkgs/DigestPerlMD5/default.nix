{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Digest-Perl-MD5";
  version = "1.9";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DE/DELTA/Digest-Perl-MD5-1.9.tar.gz";
    hash = "sha256-cQDLoXEPRfsOkH2LGnvYyu81xkrNMdfyJa/1r/7s2bE=";
  };
  meta = {
    description = "Perl Implementation of Rivest's MD5 algorithm";
  };
}
