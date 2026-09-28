{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatch-vcs,
  hatchling,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "platformdirs";
  version = "4.12.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tox-dev";
    repo = "platformdirs";
    tag = version;
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
    changelog = "https://github.com/tox-dev/platformdirs/releases/tag/${src.tag}";
    license = lib.licenses.mit;

  };
}
