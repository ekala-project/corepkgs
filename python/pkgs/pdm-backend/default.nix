{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,

  # propagates
  importlib-metadata,
}:

buildPythonPackage rec {
  pname = "pdm-backend";
  version = "2.4.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pdm-project";
    repo = "pdm-backend";
    tag = version;
    hash = "sha256-tXgojVE/Bh2OVeMG/P5aCK5HEeUhiypUjTrS4yOwvZU=";
  };

  env.PDM_BUILD_SCM_VERSION = version;

  dependencies = lib.optionals (pythonOlder "3.10") [ importlib-metadata ];

  pythonImportsCheck = [ "pdm.backend" ];

  setupHook = ./setup-hook.sh;

  meta = {
    homepage = "https://github.com/pdm-project/pdm-backend";
    changelog = "https://github.com/pdm-project/pdm-backend/releases/tag/${version}";
    description = "Yet another PEP 517 backend";
    license = lib.licenses.mit;

  };
}
