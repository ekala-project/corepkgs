{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "App-FatPacker";
  version = "0.010008";
  src = fetchurl {
    url = "mirror://cpan/authors/id/M/MS/MSTROUT/App-FatPacker-0.010008.tar.gz";
    hash = "sha256-Ep2zbchFZhpYIoaBDP4tUhbrLOCCutQK4fzc4PRd7M8=";
  };
  meta = {
    description = "Pack your dependencies onto your script file";
    mainProgram = "fatpack";
  };
}
