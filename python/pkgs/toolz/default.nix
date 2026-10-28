{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "toolz";
  version = "1.2.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-lmegOOnW7Lo3mV4myy9Z7GQgtq2N2Wd95Z25uVawhJA=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"setuptools-git-versioning >=2.0",' "" \
      --replace-fail 'dynamic = ["version"]' 'version = "${finalAttrs.version}"'
  '';

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "toolz/tests" ];

  pythonImportsCheck = [
    "toolz"
    "tlz"
  ];

  meta = {
    homepage = "https://github.com/pytoolz/toolz";
    description = "List processing tools and functional utilities";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
