{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
}:

buildPythonPackage rec {
  pname = "poetry-core";
  version = "2.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-poetry";
    repo = "poetry-core";
    tag = version;
    hash = "sha256-l5WTjKa+A66QfWLmrjCQq7ZrSaeuylGIRZr8jsiYq+A=";
  };

  pythonImportsCheck = [ "poetry.core" ];

  # Allow for packages to use PEP420's native namespace
  pythonNamespaces = [ "poetry" ];

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.cc.isClang "-Wno-int-conversion";

  meta = {
    changelog = "https://github.com/python-poetry/poetry-core/blob/${src.tag}/CHANGELOG.md";
    description = "Poetry PEP 517 Build Backend";
    homepage = "https://github.com/python-poetry/poetry-core/";
    license = lib.licenses.mit;
  };
}
