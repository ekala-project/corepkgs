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

  disabledTests = [
    # flaky; https://github.com/chardet/chardet/issues/256
    "test_detect_all_and_detect_one_should_agree"
  ];

  pythonImportsCheck = [ "chardet" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    changelog = "https://github.com/chardet/chardet/releases/tag/${finalAttrs.version}";
    description = "Universal encoding detector";
    mainProgram = "chardetect";
    homepage = "https://github.com/chardet/chardet";
    license = lib.licenses.lgpl21Plus;

  };
})
