{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  pythonOlder,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "fastjsonschema";
  version = "2.22.3";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "horejsek";
    repo = "python-fastjsonschema";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-KbgY8wJW5BHo1EUZzY+dUlNN4Bk/8DFHxQHkVNHoHKA=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  disabledTests = [
    "benchmark"
    # these tests require network access
    "remote ref"
    "definitions"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "test_compile_to_code_custom_format" # cannot import temporary module created during test
  ];

  disabledTestPaths = [
    # fastjsonschema.exceptions.JsonSchemaDefinitionException: Unknown format uuid/duration
    "tests/json_schema/test_draft2019.py::test"
  ];

  pythonImportsCheck = [ "fastjsonschema" ];

  meta = {
    description = "JSON schema validator for Python";
    downloadPage = "https://github.com/horejsek/python-fastjsonschema";
    homepage = "https://horejsek.github.io/python-fastjsonschema/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
