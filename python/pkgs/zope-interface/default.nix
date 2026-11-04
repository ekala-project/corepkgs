{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "zope-interface";
  version = "8.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "zopefoundation";
    repo = "zope.interface";
    tag = finalAttrs.version;
    hash = "sha256-JDBfBlqQ2WbnF1fkPjL7brDPbPG0LYEAZ+/DBui3KYw=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "zope.interface" ];

  pythonNamespaces = [ "zope" ];

  meta = {
    changelog = "https://github.com/zopefoundation/zope.interface/blob/${finalAttrs.version}/CHANGES.rst";
    description = "Zope.Interface";
    homepage = "https://github.com/zopefoundation/zope.interface";
    license = lib.licenses.zpl21;
    platforms = lib.platforms.unix;
  };
})
