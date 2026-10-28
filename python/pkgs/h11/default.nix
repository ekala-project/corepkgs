{
  lib,
  buildPythonPackage,
  fetchPypi,
  pytestCheckHook,
  httpcore,
  httpx,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "h11";
  version = "0.16.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-TjW5Vs9FeS5MqliF5p+6AL28b/r7+gIDAOVJsgjuX/E=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  # Some of the tests use localhost networking.
  __darwinAllowLocalNetworking = true;

  passthru.tests = {
    inherit httpcore httpx;
  };

  pythonImportsCheck = [ "h11" ];

  meta = {
    description = "Pure-Python, bring-your-own-I/O implementation of HTTP/1.1";
    homepage = "https://github.com/python-hyper/h11";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
