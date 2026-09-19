{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
  tomli,
}:

buildPythonPackage (finalAttrs: {
  pname = "tomli-w";
  version = "1.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "hukkin";
    repo = "tomli-w";
    rev = finalAttrs.version;
    hash = "sha256-Du37ySvAL9iwGec5wbWxwLTYm+kcDSOs5OJ5Sw7R87g=";
  };

  build-system = [ flit-core ];

  nativeCheckInputs = [
    pytestCheckHook
    tomli
  ];

  testPaths = [
    "tests"
    "benchmark"
  ];

  # test_for_profiler needs benchmark/data.toml which may not be present in all source archives
  disabledTestPaths = [ "tests/test_for_profiler.py" ];

  pythonImportsCheck = [ "tomli_w" ];

  meta = {
    description = "Write-only counterpart to Tomli, which is a read-only TOML parser";
    homepage = "https://github.com/hukkin/tomli-w";
    changelog = "https://github.com/hukkin/tomli-w/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
  };
})
