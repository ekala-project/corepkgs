{
  buildPerlModule,
  fetchurl,
  ModuleBuildTiny,
}:

buildPerlModule {
  pname = "Devel-CheckCompiler";
  version = "0.07";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SY/SYOHEX/Devel-CheckCompiler-0.07.tar.gz";
    hash = "sha256-dot2l7S41NNyx1B7ZendJqpCI/cQAYO7tNOvRtQ4abU=";
  };
  buildInputs = [ ModuleBuildTiny ];
  meta = {
    description = "Check the compiler's availability";
    homepage = "https://github.com/tokuhirom/Devel-CheckCompiler";
  };
}
