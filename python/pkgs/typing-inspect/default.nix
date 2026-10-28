{
  lib,
  buildPythonPackage,
  fetchPypi,
  typing-extensions,
  mypy-extensions,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "typing-inspect";
  version = "0.9.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit (finalAttrs) version;
    pname = "typing_inspect";
    hash = "sha256-sj/EL/b272lU5IUsH7USzdGNvqAxNPkfhWqVzMlGH3g=";
  };

  propagatedBuildInputs = [
    typing-extensions
    mypy-extensions
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = [
    # https://github.com/ilevkivskyi/typing_inspect/issues/84
    "test_typed_dict_typing_extension"
  ];

  pythonImportsCheck = [ "typing_inspect" ];

  meta = {
    description = "Runtime inspection utilities for Python typing module";
    homepage = "https://github.com/ilevkivskyi/typing_inspect";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
