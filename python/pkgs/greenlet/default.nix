{
  stdenv,
  lib,
  buildPythonPackage,
  fetchPypi,

  # build-system
  setuptools,

  # tests
  objgraph ? null,
  psutil,
  python,
  unittestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "greenlet";
  version = "3.5.6";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-jmfEO9/IjV/ubbDT5AF1s2L8lfuF8EEtIzubIDxTpXU=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [
    psutil
    unittestCheckHook
  ]
  ++ lib.optional (objgraph != null) objgraph;

  # https://github.com/python-greenlet/greenlet/issues/395
  env.NIX_CFLAGS_COMPILE = lib.optionalString (
    stdenv.hostPlatform.isPower64 || stdenv.hostPlatform.isLoongArch64
  ) "-fomit-frame-pointer";

  preCheck = ''
    pushd ${placeholder "out"}/${python.sitePackages}
  '';

  unittestFlagsArray = [ "greenlet.tests" ];

  postCheck = ''
    popd
  '';

  passthru.tests.pytest = finalAttrs.finalPackage.overridePythonAttrs (_: {
    doCheck = true;
  });

  pythonImportsCheck = [ "greenlet" ];

  meta = {
    changelog = "https://github.com/python-greenlet/greenlet/blob/${finalAttrs.version}/CHANGES.rst";
    homepage = "https://github.com/python-greenlet/greenlet";
    description = "Module for lightweight in-process concurrent programming";
    license = with lib.licenses; [
      psfl # src/greenlet/slp_platformselect.h & files in src/greenlet/platform/ directory
      mit
    ];
  };
})
