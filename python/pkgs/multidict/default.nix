{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "multidict";
  version = "7.2.1";
  pyproject = true;

  disabled = pythonOlder "3.11";

  src = fetchFromGitHub {
    owner = "aio-libs";
    repo = "multidict";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qxBtZg04UED64H5QRBb1Hw5O3pY4I/Jy/N7HamgwKzM=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "multidict" ];

  meta = {
    description = "Multidict implementation";
    homepage = "https://github.com/aio-libs/multidict";
    changelog = "https://github.com/aio-libs/multidict/blob/v${finalAttrs.version}/CHANGES.rst";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
