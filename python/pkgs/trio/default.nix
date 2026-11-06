{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,

  # build-system
  setuptools,

  # dependencies
  attrs,
  idna,
  outcome,
  sniffio,
  sortedcontainers,
}:

buildPythonPackage (finalAttrs: {
  pname = "trio";
  version = "0.35.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-trio";
    repo = "trio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jfFcnmm86I1MuKL0zNCzf2Ms3RUCFfGctJz52FPI6cU=";
  };

  build-system = [ setuptools ];

  dependencies = [
    attrs
    idna
    outcome
    sniffio
    sortedcontainers
  ];

  __darwinAllowLocalNetworking = true;

  pythonImportsCheck = [ "trio" ];

  meta = {
    changelog = "https://github.com/python-trio/trio/blob/${finalAttrs.src.tag}/docs/source/history.rst";
    description = "Async/await-native I/O library for humans and snake people";
    homepage = "https://github.com/python-trio/trio";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.all;
  };
})
