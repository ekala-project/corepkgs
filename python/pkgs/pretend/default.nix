{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  pythonOlder,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "pretend";
  version = "1.0.9";
  pyproject = true;

  build-system = [ setuptools ];

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "alex";
    repo = "pretend";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OqMfeIMFNBBLq6ejR3uOCIHZ9aA4zew7iefVlAsy1JQ=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pretend" ];

  meta = {
    description = "Module for stubbing";
    homepage = "https://github.com/alex/pretend";
    license = lib.licenses.bsd3;

  };
})
