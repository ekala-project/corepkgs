{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Text-Glob";
  version = "0.11";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RC/RCLAMP/Text-Glob-0.11.tar.gz";
    hash = "sha256-BpzNSdPwot7bEV9L3J+6wHqDWShAlT0fzfw5650wUoc=";
  };
  meta = {
    description = "Match globbing patterns against text";
  };
}
