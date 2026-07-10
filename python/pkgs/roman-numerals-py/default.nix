{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  roman-numerals,
}:

buildPythonPackage rec {
  pname = "roman-numerals-py";
  version = "4.1.0";
  pyproject = true;

  src = fetchPypi {
    pname = "roman_numerals_py";
    inherit version;
    hash = "sha256-9deytMpS3YVe96uOs1kPQowLHqSAc2zjKwH+8qX42vk=";
  };

  build-system = [ setuptools ];

  dependencies = [ roman-numerals ];

  pythonImportsCheck = [ "roman_numerals" ];

  meta = {
    description = "Deprecated shim for roman-numerals";
    homepage = "https://github.com/AA-Turner/roman-numerals/";
    license = lib.licenses.cc0;
    platforms = lib.platforms.all;
  };
}
