{
  buildPerlPackage,
  fetchurl,
  unzip,
}:

buildPerlPackage {
  pname = "Algorithm-Diff";
  version = "1.1903";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TY/TYEMQ/Algorithm-Diff-1.1903.tar.gz";
    hash = "sha256-MOhKxLMdQLZik/exIhMxxaUFYaOdWA2FAE2cH/+ZF1E=";
  };
  buildInputs = [ unzip ];
  meta = {
    description = "Compute 'intelligent' differences between two files / lists";
  };
}
