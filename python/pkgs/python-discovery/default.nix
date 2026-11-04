{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatch-fancy-pypi-readme,
  hatch-vcs,
  hatchling,
  filelock,
}:

buildPythonPackage (finalAttrs: {
  pname = "python-discovery";
  version = "1.9.2";
  pyproject = true;

  src = fetchPypi {
    pname = "python_discovery";
    inherit (finalAttrs) version;
    hash = "sha256-3jl7nEsJpfuLtMUds8DacfuB0ig3GNdP0e+qv/wyr7w=";
  };

  build-system = [
    hatch-fancy-pypi-readme
    hatch-vcs
    hatchling
  ];

  dependencies = [ filelock ];

  pythonImportsCheck = [ "python_discovery" ];

  meta = {
    description = "Python interpreter discovery";
    homepage = "https://github.com/tox-dev/python-discovery";
    changelog = "https://github.com/tox-dev/python-discovery/blob/${finalAttrs.version}/docs/changelog.rst";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
