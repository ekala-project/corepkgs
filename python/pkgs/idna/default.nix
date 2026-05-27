{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "idna";
  version = "3.11";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kjd";
    repo = "idna";
    tag = "v${finalAttrs.version}";
    hash = "sha256-4mnWOit+lrZnVslVyfalt6lv7qSYpLlyvET553SplJU=";
  };

  build-system = [ flit-core ];

  pythonImportsCheck = [ "idna" ];

  nativeCheckInputs = [ pytestCheckHook ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    homepage = "https://github.com/kjd/idna/";
    changelog = "https://github.com/kjd/idna/releases/tag/${finalAttrs.src.tag}";
    description = "Internationalized Domain Names in Applications (IDNA)";
    license = lib.licenses.bsd3;

  };
})
