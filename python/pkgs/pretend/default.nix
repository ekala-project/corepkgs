{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage (finalAttrs: {
  pname = "pretend";
  version = "1.0.9";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "alex";
    repo = "pretend";
    rev = "v${finalAttrs.version}";
    hash = "sha256-OqMfeIMFNBBLq6ejR3uOCIHZ9aA4zew7iefVlAsy1JQ=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pretend" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Module for stubbing";
    homepage = "https://github.com/alex/pretend";
    license = lib.licenses.bsd3;

  };
})
