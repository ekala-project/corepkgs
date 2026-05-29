{
  lib,
  buildPythonPackage,
  fetchPypi,
  hypothesis,
  pythonOlder,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "chardet";
  version = "5.2.0";
  format = "pyproject";
  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-Gztv9HmoxBS8P6LAhSmVaVxKAm3NbQYzst0JLKOcHPc=";
  };

  nativeBuildInputs = [ setuptools ];

  nativeCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  # chardet's test runner is a single `test.py` at the source root, with
  # `setup.cfg` configuring pytest to use `python_files = test.py` and
  # `tests/` containing the sample data files it loads.
  testPaths = [
    "tests"
    "test.py"
  ];

  disabledTests = [
    # flaky; https://github.com/chardet/chardet/issues/256
    "test_detect_all_and_detect_one_should_agree"
  ];

  pythonImportsCheck = [ "chardet" ];

  meta = {
    changelog = "https://github.com/chardet/chardet/releases/tag/${finalAttrs.version}";
    description = "Universal encoding detector";
    mainProgram = "chardetect";
    homepage = "https://github.com/chardet/chardet";
    license = lib.licenses.lgpl21Plus;

  };
})
