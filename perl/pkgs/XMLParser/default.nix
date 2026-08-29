{
  buildPerlPackage,
  expat,
  fetchurl,
  lib,
  LWP,
  stdenv,
}:

buildPerlPackage {
  pname = "XML-Parser";
  version = "2.46";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz";
    hash = "sha256-0zEzJJHFHMz7TLlP/ET5zXM3jmGEmNSjffngQ2YcUV0=";
  };
  patches = [ ./xml-parser-0001-HACK-Assumes-Expat-paths-are-good.patch ];
  postPatch =
    lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform) ''
      substituteInPlace Expat/Makefile.PL --replace 'use English;' '#'
    ''
    + lib.optionalString stdenv.hostPlatform.isCygwin ''
      sed -i -e "s@my \$compiler = File::Spec->catfile(\$path, \$cc\[0\]) \. \$Config{_exe};@my \$compiler = File::Spec->catfile(\$path, \$cc\[0\]) \. (\$^O eq 'cygwin' ? \"\" : \$Config{_exe});@" inc/Devel/CheckLib.pm
    '';
  makeMakerFlags = [
    "EXPATLIBPATH=${expat.out}/lib"
    "EXPATINCPATH=${expat.dev}/include"
  ];
  propagatedBuildInputs = [ LWP ];
  meta = {
    description = "Perl module for parsing XML documents";
  };
}
