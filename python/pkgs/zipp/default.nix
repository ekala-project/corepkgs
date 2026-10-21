{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  func-timeout,
  jaraco-itertools,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage (finalAttrs: {
  pname = "zipp";
  version = "4.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jaraco";
    repo = "zipp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-yQXgsSUFzZ4LYDpsa9HZVJl7jNNIqCL11sVHvvcKWpg=";
  };

  postPatch = ''
    # Downloads license text at build time
    sed -i "/coherent\.licensed/d" pyproject.toml
  '';

  build-system = [
    setuptools
    setuptools-scm
  ];

  nativeCheckInputs = [
    func-timeout
    jaraco-itertools
  ];

  pythonImportsCheck = [ "zipp" ];

  passthru.tests = {
    check = finalAttrs.finalPackage.overridePythonAttrs (_: {
      doCheck = true;
    });
  };

  meta = {
    description = "Pathlib-compatible object wrapper for zip files";
    homepage = "https://github.com/jaraco/zipp";
    license = lib.licenses.mit;
  };
})
