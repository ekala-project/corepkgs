{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "zope-event";
  version = "5.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "zopefoundation";
    repo = "zope.event";
    tag = finalAttrs.version;
    hash = "sha256-B4DGCbPS4KNf1BFLeF7ousjIOehB0/8V+jXBQzS2ZN4=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "setuptools == 78.1.1" "setuptools >= 78.1.1"
  '';

  build-system = [ setuptools ];

  pythonImportsCheck = [ "zope.event" ];

  nativeCheckInputs = [ pytestCheckHook ];

  enabledTestPaths = [ "src/zope/event/tests.py" ];

  pythonNamespaces = [ "zope" ];

  meta = {
    description = "Event publishing system";
    homepage = "https://github.com/zopefoundation/zope.event";
    changelog = "https://github.com/zopefoundation/zope.event/blob/${finalAttrs.src.tag}/CHANGES.rst";
    license = lib.licenses.zpl21;
    platforms = lib.platforms.all;
  };
})
