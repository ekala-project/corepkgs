{
  AlgorithmDiff,
  buildPerlPackage,
  fetchurl,
  Spiffy,
  TextDiff,
}:

buildPerlPackage {
  pname = "Test-Base";
  version = "0.89";
  src = fetchurl {
    url = "mirror://cpan/authors/id/I/IN/INGY/Test-Base-0.89.tar.gz";
    hash = "sha256-J5Shqq6x06KH3SxyhiWGY3llYvfbnMxrQkvE8d6K0BQ=";
  };
  propagatedBuildInputs = [ Spiffy ];
  buildInputs = [
    AlgorithmDiff
    TextDiff
  ];
  meta = {
    description = "Data Driven Testing Framework";
  };
}
