{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatch-vcs,
  hatchling,
  pythonOlder,
}:

buildPythonPackage (finalAttrs: {
  pname = "platformdirs";
  version = "4.12.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tox-dev";
    repo = "platformdirs";
    tag = finalAttrs.version;
    hash = "sha256-7AtmBcPmm+k8kXdbTJTRw3iyjKEKr01tvseMHstrEPU=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];

  pythonImportsCheck = [ "platformdirs" ];

  meta = {
    description = "Module for determining appropriate platform-specific directories";
    homepage = "https://platformdirs.readthedocs.io/";
    changelog = "https://github.com/tox-dev/platformdirs/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;

  };
})
