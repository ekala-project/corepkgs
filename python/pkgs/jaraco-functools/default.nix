{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  jaraco-classes,
  more-itertools,
  pytestCheckHook,
  setuptools-scm,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "jaraco-functools";
  version = "4.5.0";
  pyproject = true;

  src = fetchPypi {
    pname = "jaraco_functools";
    inherit (finalAttrs) version;
    hash = "sha256-O7VmXqSgIM94pwQOiRVMd+2ts8p082ZHlmnFmZqnCwM=";
  };

  postPatch = ''
    sed -i "/coherent\.licensed/d" pyproject.toml
  '';

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [ more-itertools ];

  nativeCheckInputs = [
    jaraco-classes
    pytestCheckHook
  ];

  # test is flaky on darwin
  disabledTests = if stdenv.hostPlatform.isDarwin then [ "test_function_throttled" ] else null;

  pythonNamespaces = [ "jaraco" ];

  pythonImportsCheck = [ "jaraco.functools" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Additional functools in the spirit of stdlib's functools";
    homepage = "https://github.com/jaraco/jaraco.functools";
    changelog = "https://github.com/jaraco/jaraco.functools/blob/v${finalAttrs.version}/NEWS.rst";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
