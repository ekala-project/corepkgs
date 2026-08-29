{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "YAML-Syck";
  version = "1.34";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TODDR/YAML-Syck-1.34.tar.gz";
    hash = "sha256-zJFWzK69p5jr/i8xthnoBld/hg7RcEJi8X/608bjQVk=";
  };
  meta = {
    description = "Fast, lightweight YAML loader and dumper";
    homepage = "https://github.com/toddr/YAML-Syck";
    license = with lib.licenses; [ mit ];
  };
}
