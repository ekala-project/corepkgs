{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "ephemeral-port-reserve";
  version = "1.1.4";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "Yelp";
    repo = "ephemeral-port-reserve";
    rev = "v${finalAttrs.version}";
    hash = "sha256-R6NRpfaT05PO/cTWgCakiGfCuCyucjVOXbAezn5x1cU=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = lib.optionals stdenv.hostPlatform.isDarwin [
    # can't find hostname in our darwin build environment
    "test_fqdn"
  ];

  __darwinAllowLocalNetworking = true;

  pythonImportsCheck = [ "ephemeral_port_reserve" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Find an unused port, reliably";
    mainProgram = "ephemeral-port-reserve";
    homepage = "https://github.com/Yelp/ephemeral-port-reserve/";
    license = lib.licenses.mit;
  };
})
