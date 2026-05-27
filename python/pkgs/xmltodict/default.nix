{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "xmltodict";
  version = "1.0.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "martinblech";
    repo = "xmltodict";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gnTNkh0GLfRmjMsLhfvpNrewfinNOhem0i3wzIZvKpA=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "xmltodict" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Makes working with XML feel like you are working with JSON";
    homepage = "https://github.com/martinblech/xmltodict";
    changelog = "https://github.com/martinblech/xmltodict/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
