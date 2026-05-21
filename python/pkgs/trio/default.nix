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

buildPythonPackage rec {
  pname = "trio";
  version = "0.32.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-trio";
    repo = "trio";
    tag = "v${version}";
    hash = "sha256-kZKP5TFg9M+NCx9V9B0qNbGiwZtBPtgVKgZYjX5w1ok=";
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

  doCheck = false;

  pythonImportsCheck = [ "trio" ];

  meta = {
    changelog = "https://github.com/python-trio/trio/blob/${src.tag}/docs/source/history.rst";
    description = "Async/await-native I/O library for humans and snake people";
    homepage = "https://github.com/python-trio/trio";
    license = with lib.licenses; [
      mit
      asl20
    ];
  };
}
