{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "parso";
  version = "0.8.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "davidhalter";
    repo = "parso";
    tag = "v${finalAttrs.version}";
    hash = "sha256-faSXCrOkybLr0bboF/8rPV/Humq8s158A3UOpdlYi0I=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "test" ];

  meta = {
    description = "Python Parser";
    homepage = "https://parso.readthedocs.io/en/latest/";
    changelog = "https://github.com/davidhalter/parso/blob/${finalAttrs.src.tag}/CHANGELOG.rst";
    license = lib.licenses.mit;
  };
})
