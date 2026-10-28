{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  python,
}:

buildPythonPackage (finalAttrs: {
  pname = "lit";
  version = "18.1.8";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-R8F0oYaUGugw8E3tdqNERgC+Z9Xl+4KCw3g/umccTts=";
  };

  nativeBuildInputs = [ setuptools ];

  passthru = {
    inherit python;
    ekapkgs-update.semver-strategy = "minor";
  };

  pythonImportsCheck = [ "lit" ];

  meta = {
    description = "Portable tool for executing LLVM and Clang style test suites";
    mainProgram = "lit";
    homepage = "http://llvm.org/docs/CommandGuide/lit.html";
    license = lib.licenses.ncsa;
    platforms = lib.platforms.all;
  };
})
