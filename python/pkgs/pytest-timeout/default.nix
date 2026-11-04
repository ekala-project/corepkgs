{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytest,
  pytestCheckHook,
  pexpect,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-timeout";
  version = "2.5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-timeout";
    tag = finalAttrs.version;
    hash = "sha256-9eoYrWPOBh7jA1vpQ7ODOTkAzeTh6EIydsEkSLTY8xw=";
  };

  build-system = [ setuptools ];

  buildInputs = [ pytest ];

  nativeCheckInputs = [
    pytestCheckHook
    pexpect
  ];

  pythonImportsCheck = [ "pytest_timeout" ];

  meta = {
    description = "Pytest plugin to abort hanging tests";
    homepage = "https://github.com/pytest-dev/pytest-timeout/";
    changelog = "https://github.com/pytest-dev/pytest-timeout/tree/${finalAttrs.src.tag}#changelog";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
