{
  buildPerlModule,
  fetchurl,
  lib,
  ModuleBuildTiny,
}:

buildPerlModule {
  pname = "Readonly";
  version = "2.05";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SA/SANKO/Readonly-2.05.tar.gz";
    hash = "sha256-SyNUJJGvAQ1EpcfIYSRHOKzHSrq65riDjTVN+xlGK14=";
  };
  buildInputs = [ ModuleBuildTiny ];
  meta = {
    description = "Facility for creating read-only scalars, arrays, hashes";
    homepage = "https://github.com/sanko/readonly";
    license = with lib.licenses; [ artistic2 ];
  };
}
