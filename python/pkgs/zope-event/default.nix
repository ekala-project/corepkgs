{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "zope-event";
  version = "5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "zopefoundation";
    repo = "zope.event";
    tag = finalAttrs.version;
    hash = "sha256-85jXSrploTcskdOBI84KGGf9Bno41ZTtT/TrbgmTxiA=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "zope.event" ];

  nativeCheckInputs = [ pytestCheckHook ];

  enabledTestPaths = [ "src/zope/event/tests.py" ];

  pythonNamespaces = [ "zope" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Event publishing system";
    homepage = "https://github.com/zopefoundation/zope.event";
    changelog = "https://github.com/zopefoundation/zope.event/blob/${finalAttrs.src.tag}/CHANGES.rst";
    license = lib.licenses.zpl21;
  };
})
