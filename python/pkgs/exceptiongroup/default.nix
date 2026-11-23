{
  lib,
  buildPythonPackage,
  fetchPypi,
  flit-core,
  pytestCheckHook,
  pythonAtLeast,
  pythonOlder,
  typing-extensions,
}:

buildPythonPackage (finalAttrs: {
  pname = "exceptiongroup";
  version = "1.3.2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-yoLmnwy1Nfvek0iFdEtnZpo+/d1Q/nvADTOYg5/K3ew=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'requires = ["flit_scm"]' 'requires = ["flit_core"]' \
      --replace-fail 'build-backend = "flit_scm:buildapi"' 'build-backend = "flit_core.buildapi"' \
      --replace-fail 'dynamic = ["version"]' 'version = "${finalAttrs.version}"'
  '';

  build-system = [ flit-core ];

  dependencies = lib.optionals (pythonOlder "3.13") [ typing-extensions ];

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = lib.optionals (pythonAtLeast "3.14") [
    # repr change in Python 3.14
    "test_exceptions_mutate_original_sequence"
  ];

  testPaths = [ "tests" ];

  doCheck = pythonAtLeast "3.11"; # infinite recursion with pytest

  pythonImportsCheck = [ "exceptiongroup" ];

  meta = {
    description = "Backport of PEP 654 (exception groups)";
    homepage = "https://github.com/agronholm/exceptiongroup";
    changelog = "https://github.com/agronholm/exceptiongroup/blob/${finalAttrs.version}/CHANGES.rst";
    license = with lib.licenses; [ mit ];
    platforms = lib.platforms.all;
  };
})
