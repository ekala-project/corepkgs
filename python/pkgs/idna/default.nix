{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "idna";
  version = "3.18";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kjd";
    repo = "idna";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9nLy/9PNuLSQJsf4Jes0uN695+LGjz2LXlfiZxxvGV4=";
  };

  build-system = [ flit-core ];

  pythonImportsCheck = [ "idna" ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  meta = {
    homepage = "https://github.com/kjd/idna/";
    changelog = "https://github.com/kjd/idna/releases/tag/${finalAttrs.src.tag}";
    description = "Internationalized Domain Names in Applications (IDNA)";
    license = lib.licenses.bsd3;

  };
})
