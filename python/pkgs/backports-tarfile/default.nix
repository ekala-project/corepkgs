{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
  wheel,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "backports-tarfile";
  version = "1.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jaraco";
    repo = "backports.tarfile";
    tag = "v${finalAttrs.version}";
    hash = "sha256-X3rkL35aDG+DnIOq0fI7CFoWGNtgLkLjtT9y6+23oto=";
  };

  build-system = [
    setuptools
    setuptools-scm
    wheel
  ];

  pythonImportsCheck = [ "backports.tarfile" ];

  meta = {
    description = "Backport of CPython tarfile module";
    homepage = "https://github.com/jaraco/backports.tarfile";
    license = lib.licenses.mit;
  };
})
