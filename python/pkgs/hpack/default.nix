{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  hypothesis,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "hpack";
  version = "4.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-hyper";
    repo = "hpack";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gZe/ABRLXoBAeH/mp/yIgDj56jalyiYgs4EP2qK17Ig=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'requires = ["setuptools>=82"' 'requires = ["setuptools>=80"'
  '';

  build-system = [ setuptools ];

  nativeCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "hpack" ];

  meta = {
    changelog = "https://github.com/python-hyper/hpack/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    description = "Pure-Python HPACK header compression";
    homepage = "https://github.com/python-hyper/hpack";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
