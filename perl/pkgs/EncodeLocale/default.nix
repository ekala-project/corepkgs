{
  buildPerlPackage,
  fetchurl,
  stdenv,
}:

buildPerlPackage {
  pname = "Encode-Locale";
  version = "1.05";
  src = fetchurl {
    url = "mirror://cpan/authors/id/G/GA/GAAS/Encode-Locale-1.05.tar.gz";
    hash = "sha256-F2+gJ3H1QqTvsdvCpMko6PQ5G/QHhHO9YEDY8RrbDsE=";
  };
  preCheck =
    if stdenv.hostPlatform.isCygwin then
      ''
        sed -i -e "s@plan tests => 13@plan tests => 10@" t/env.t
        sed -i -e "s@ok(env(\"\\\x@#ok(env(\"\\\x@" t/env.t
        sed -i -e "s@ok(\$ENV{\"\\\x@#ok(\$ENV{\"\\\x@" t/env.t
      ''
    else
      null;
  meta = {
    description = "Determine the locale encoding";
  };
}
