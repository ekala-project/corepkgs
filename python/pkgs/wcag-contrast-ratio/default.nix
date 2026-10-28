{
  lib,
  buildPythonPackage,
  fetchPypi,
  hypothesis,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "wcag-contrast-ratio";
  version = "0.9";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-aRkrjlwKfQ3F/xGH7rPjmBQWM6S95RxpyH9Y/oftNhw=";
  };

  nativeCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  enabledTestPaths = [ "test.py" ];

  pythonImportsCheck = [ "wcag_contrast_ratio" ];

  meta = {
    description = "Library for computing contrast ratios, as required by WCAG 2.0";
    homepage = "https://github.com/gsnedders/wcag-contrast-ratio";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
