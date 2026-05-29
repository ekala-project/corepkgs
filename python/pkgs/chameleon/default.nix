{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  importlib-metadata,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage (finalAttrs: {
  pname = "chameleon";
  version = "4.6.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "malthe";
    repo = "chameleon";
    tag = finalAttrs.version;
    hash = "sha256-zCEM5yl8Y11FbexD7veS9bFJgm30L6fsTde59m2t1ec=";
  };

  build-system = [ setuptools ];

  dependencies = lib.optionals (pythonOlder "3.10") [ importlib-metadata ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "src/chameleon/tests" ];

  pythonImportsCheck = [ "chameleon" ];

  meta = {
    changelog = "https://github.com/malthe/chameleon/blob/${finalAttrs.src.tag}/CHANGES.rst";
    description = "Fast HTML/XML Template Compiler";
    downloadPage = "https://github.com/malthe/chameleon";
    homepage = "https://chameleon.readthedocs.io";
    license = lib.licenses.bsd0;

  };
})
