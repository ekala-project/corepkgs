{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytest-asyncio,
  pytest-httpserver ? null,
  pytestCheckHook,
  pythonOlder,
  pyyaml,
  requests,
  setuptools,
  tomli,
  tomli-w,
  types-pyyaml ? null,
  types-toml ? null,
  urllib3,
}:

buildPythonPackage (finalAttrs: {
  pname = "responses";
  version = "0.25.7";
  pyproject = true;

  disabled = pythonOlder "3.8";

  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "getsentry";
    repo = "responses";
    tag = finalAttrs.version;
    hash = "sha256-eiJwu0sRtr3S4yAnbsIak7g03CNqOTS16rNXoXRQumA=";
  };

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    pyyaml
    requests
    urllib3
  ]
  ++ lib.optional (types-pyyaml != null) types-pyyaml
  ++ lib.optional (types-toml != null) types-toml;

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
    tomli-w
  ]
  ++ lib.optional (pytest-httpserver != null) pytest-httpserver
  ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  testPaths = [ "responses/tests" ];

  pythonImportsCheck = [ "responses" ];

  meta = {
    description = "Python module for mocking out the requests Python library";
    homepage = "https://github.com/getsentry/responses";
    changelog = "https://github.com/getsentry/responses/blob/${finalAttrs.src.tag}/CHANGES";
    license = lib.licenses.asl20;

  };
})
