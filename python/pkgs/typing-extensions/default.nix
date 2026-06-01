{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,

  # reverse dependencies
  mashumaro,
  pydantic,
}:

buildPythonPackage rec {
  pname = "typing-extensions";
  version = "4.7.0rc1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python";
    repo = "typing_extensions";
    tag = version;
    hash = "sha256-gAbGFxVxQGsft5mWBFjBulf36eLHh5xUQDoshj1TNTs=";
  };

  build-system = [ flit-core ];

  pythonImportsCheck = [ "typing_extensions" ];

  passthru.tests = {
    inherit mashumaro pydantic;
  };

  meta = {
    description = "Backported and Experimental Type Hints for Python";
    changelog = "https://github.com/python/typing_extensions/blob/${version}/CHANGELOG.md";
    homepage = "https://github.com/python/typing";
    license = lib.licenses.psfl;
  };
}
