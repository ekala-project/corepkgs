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
  version = "4.13.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tox-dev";
    repo = "platformdirs";
    tag = finalAttrs.version;
    hash = "sha256-94PFQuqqDdP90P3ifM5ZxyLi6Yo3V/J6ast5J/o8qkE=";
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
