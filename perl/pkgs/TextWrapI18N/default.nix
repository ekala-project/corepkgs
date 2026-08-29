{
  buildPerlPackage,
  fetchurl,
  glibcLocales,
  lib,
  stdenv,
  TextCharWidth,
  unixtools,
}:

buildPerlPackage {
  pname = "Text-WrapI18N";
  version = "0.06";
  src = fetchurl {
    url = "mirror://cpan/authors/id/K/KU/KUBOTA/Text-WrapI18N-0.06.tar.gz";
    hash = "sha256-S9KaF/DCx5LRLBAFs8J28qsPrjnACFmuF0HXlBhGpIg=";
  };
  buildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin) [ glibcLocales ];
  propagatedBuildInputs = [ TextCharWidth ];
  preConfigure = ''
    substituteInPlace WrapI18N.pm --replace '/usr/bin/locale' '${unixtools.locale}/bin/locale'
  '';
  meta = {
    description = "Line wrapping module with support for multibyte, fullwidth, and combining characters and languages without whitespaces between words";
  };
}
