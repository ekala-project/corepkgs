{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-scm ? null,
  pytestCheckHook,
  pythonAtLeast,
  pythonOlder,
  typing-extensions,
}:

buildPythonPackage (finalAttrs: {
  pname = "exceptiongroup";
  version = "1.3.0";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "agronholm";
    repo = "exceptiongroup";
    tag = finalAttrs.version;
    hash = "sha256-b3Z1NsYKp0CecUq8kaC/j3xR/ZZHDIw4MhUeadizz88=";
  };

  build-system = lib.optional (flit-scm != null) flit-scm;

  dependencies = lib.optionals (pythonOlder "3.13") [ typing-extensions ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  doCheck = pythonAtLeast "3.11"; # infinite recursion with pytest

  pythonImportsCheck = [ "exceptiongroup" ];

  meta = {
    description = "Backport of PEP 654 (exception groups)";
    homepage = "https://github.com/agronholm/exceptiongroup";
    changelog = "https://github.com/agronholm/exceptiongroup/blob/${finalAttrs.version}/CHANGES.rst";
    license = with lib.licenses; [ mit ];

  };
})
