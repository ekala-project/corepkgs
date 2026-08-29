{
  buildPerlPackage,
  fetchurl,
  TestWarnings,
}:

buildPerlPackage {
  pname = "File-Slurper";
  version = "0.014";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/File-Slurper-0.014.tar.gz";
    hash = "sha256-1aNkhzOYiMPNdY5kgWDuHXDrQVPKy6/1eEbbzvs0Sww=";
  };
  buildInputs = [ TestWarnings ];
  meta = {
    description = "Simple, sane and efficient module to slurp a file";
  };
}
