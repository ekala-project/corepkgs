{
  AlgorithmDiff,
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Text-Diff";
  version = "1.45";
  src = fetchurl {
    url = "mirror://cpan/authors/id/N/NE/NEILB/Text-Diff-1.45.tar.gz";
    hash = "sha256-6Lqgexs/U+AK82NomLv3OuyaD/OPlFNu3h2+lu8IbwQ=";
  };
  propagatedBuildInputs = [ AlgorithmDiff ];
  meta = {
    description = "Perform diffs on files and record sets";
  };
}
