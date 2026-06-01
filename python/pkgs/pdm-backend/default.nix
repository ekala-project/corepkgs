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
  version = "2.4.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pdm-project";
    repo = "pdm-backend";
    tag = version;
    hash = "sha256-zh+JP1sX+ra3Z6oVgxOabwMmD/bQjokdb0MelZ0k1KQ=";
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
