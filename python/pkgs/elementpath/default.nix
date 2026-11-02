{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "elementpath";
  version = "5.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "sissaschool";
    repo = "elementpath";
    tag = "v${finalAttrs.version}";
    hash = "sha256-07PPYRFRhQZOERoaJw9a70fytitHedbKTp+cpFKY5G0=";
  };

  build-system = [ setuptools ];

  # avoid circular dependency with xmlschema which directly depends on this
  nativeCheckInputs = [ ];

  pythonImportsCheck = [ "elementpath" ];

  meta = {
    description = "XPath 1.0/2.0 parsers and selectors for ElementTree and lxml";
    homepage = "https://github.com/sissaschool/elementpath";
    changelog = "https://github.com/sissaschool/elementpath/blob/${finalAttrs.src.tag}/CHANGELOG.rst";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
