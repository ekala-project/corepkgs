{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  gitUpdater,
  setuptools,
  unittestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pycparser";
  version = "3.11";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "eliben";
    repo = "pycparser";
    tag = "release_v${finalAttrs.version}";
    hash = "sha256-Gtu9ZY5Zydu9LI6tMQiOLWj6hgyw1Tub7c989fDp2q0=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "pycparser" ];

  nativeCheckInputs = [ unittestCheckHook ];

  unittestFlagsArray = [
    "-s"
    "tests"
  ];

  passthru.updateScript = gitUpdater {
    rev-prefix = "release_v";
  };

  meta = {
    changelog = "https://github.com/eliben/pycparser/releases/tag/${finalAttrs.src.tag}";
    description = "C parser in Python";
    homepage = "https://github.com/eliben/pycparser";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
