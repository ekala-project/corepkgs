{
  buildPerlModule,
  ExtUtilsCChecker,
  fetchurl,
  FileShareDir,
  Test2Suite,
}:

buildPerlModule {
  pname = "XS-Parse-Keyword";
  version = "0.48";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PE/PEVANS/XS-Parse-Keyword-0.48.tar.gz";
    hash = "sha256-hXoHC6Rlq1uJ1NjTbZI1jt1m5ee0qRWEYR2FElrJqcc=";
  };
  buildInputs = [
    ExtUtilsCChecker
    Test2Suite
  ];
  propagatedBuildInputs = [ FileShareDir ];
  meta = {
    description = "XS functions to assist in parsing keyword syntax";
  };
}
