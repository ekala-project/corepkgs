{
  buildPerlModule,
  fetchurl,
}:

buildPerlModule {
  pname = "Test-Fork";
  version = "0.02";
  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MS/MSCHWERN/Test-Fork-0.02.tar.gz";
    hash = "sha256-/P77+yT4havoJ8KtB6w9Th/s8hOhRxf8rzw3F1BF0D4=";
  };
  meta = {
    description = "Test code which forks";
  };
}
