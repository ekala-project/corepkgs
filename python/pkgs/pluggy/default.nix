{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools-scm,
  pythonOlder,
  callPackage,
}:

buildPythonPackage (finalAttrs: {
  pname = "pluggy";
  version = "1.6.0";

  disabled = pythonOlder "3.8";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pluggy";
    tag = finalAttrs.version;
    hash = "sha256-pkQjPJuSASWmzwzp9H/UTJBQDr2r2RiofxpF135lAgc=";
  };

  build-system = [ setuptools-scm ];

  passthru.tests = {
    pytest = callPackage ./tests.nix { };
  };

  pythonImportsCheck = [ "pluggy" ];

  meta = {
    changelog = "https://github.com/pytest-dev/pluggy/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    description = "Plugin and hook calling mechanisms for Python";
    homepage = "https://github.com/pytest-dev/pluggy";
    license = lib.licenses.mit;

  };
})
