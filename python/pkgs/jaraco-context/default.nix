{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  setuptools-scm,
  backports-tarfile,
}:

buildPythonPackage (finalAttrs: {
  pname = "jaraco-context";
  version = "6.1.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jaraco";
    repo = "jaraco.context";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gkFRBgVu79o2wCZqVdqChND+763uR6lAuWFwYHxHIq8=";
  };

  postPatch = ''
    sed -i "/coherent.licensed/d" pyproject.toml
  '';

  pythonNamespaces = [ "jaraco" ];

  build-system = [ setuptools-scm ];

  dependencies = lib.optionals (pythonOlder "3.12") [ backports-tarfile ];

  pythonImportsCheck = [ "jaraco.context" ];

  meta = {
    description = "Python module for context management";
    homepage = "https://github.com/jaraco/jaraco.context";
    changelog = "https://github.com/jaraco/jaraco.context/blob/${finalAttrs.src.tag}/CHANGES.rst";
    license = lib.licenses.mit;
  };
})
