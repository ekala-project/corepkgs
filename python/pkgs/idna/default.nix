{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "idna";
  version = "3.20";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kjd";
    repo = "idna";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RLwFtWOxsf0s1DI5sdwYY/DuXbhyADqAbp0arREIc30=";
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
