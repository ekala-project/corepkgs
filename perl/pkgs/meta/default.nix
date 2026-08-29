{
  buildPerlModule,
  fetchurl,
  Test2Suite,
}:

buildPerlModule {
  pname = "meta";
  version = "0.012";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PEVANS/meta-0.012.tar.gz";
    hash = "sha256-Fx0J0wn4APVTTQE4tXMDmpYfEDtDaKhBC3dogzFuuFk=";
  };
  buildInputs = [ Test2Suite ];
  meta = {
    description = "Meta-programming API";
  };
}
