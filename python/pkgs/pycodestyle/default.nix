{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  python,
  pytestCheckHook,
  setuptools,
  isPyPy,
}:

buildPythonPackage (finalAttrs: {
  pname = "pycodestyle";
  version = "2.15.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "PyCQA";
    repo = "pycodestyle";
    tag = finalAttrs.version;
    hash = "sha256-o/OddDPcCB/tc6qQ0OAJ5UpXaVh3zL2n8Z9BqPIrGdQ=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "pycodestyle" ];

  nativeCheckInputs = [ pytestCheckHook ];

  # `tests/` imports the `testing` helper module and `postCheck` lints
  # `pycodestyle.py` from the source root.
  testPaths = [
    "tests"
    "testing"
    "pycodestyle.py"
    "setup.py"
  ];

  # https://github.com/PyCQA/pycodestyle/blob/2.15.0/tox.ini#L16
  postCheck = ''
    ${python.interpreter} -m pycodestyle --statistics pycodestyle.py
  '';

  disabledTests = lib.optionals isPyPy [
    # PyPy reports a SyntaxError instead of ValueError
    "test_check_nullbytes"
  ];

  meta = {
    changelog = "https://github.com/PyCQA/pycodestyle/blob/${finalAttrs.src.tag}/CHANGES.txt";
    description = "Python style guide checker";
    mainProgram = "pycodestyle";
    homepage = "https://pycodestyle.pycqa.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
