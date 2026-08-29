{
  buildPerlPackage,
  DataOptList,
  fetchurl,
  namespaceclean,
}:

buildPerlPackage {
  pname = "syntax";
  version = "0.004";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PH/PHAYLON/syntax-0.004.tar.gz";
    hash = "sha256-/hm22oqPQ6WqLuVxRBvA4zn7FW0AgcFXoaJOmBLH02U=";
  };
  propagatedBuildInputs = [
    DataOptList
    namespaceclean
  ];
  meta = {
    description = "Activate syntax extensions";
    homepage = "https://github.com/phaylon/syntax/wiki";
  };
}
