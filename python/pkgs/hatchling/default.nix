{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,

  # runtime
  editables,
  packaging,
  pathspec,
  pluggy,
  tomli,
  tomlkit,
  trove-classifiers,

  # tests
  build,
  python,
  requests,
  virtualenv,
}:

buildPythonPackage (finalAttrs: {
  pname = "hatchling";
  version = "1.32.4";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-xEaPcxRMBU0qq07w8DeMQ7mHi/B/j/1reWkOlw03Xwc=";
  };

  # listed in backend/pyproject.toml
  dependencies = [
    editables
    packaging
    pathspec
    pluggy
    tomlkit
    trove-classifiers
  ]
  ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  pythonImportsCheck = [
    "hatchling"
    "hatchling.build"
  ];

  # listed in /backend/tests/downstream/requirements.txt
  nativeCheckInputs = [
    build
    requests
    virtualenv
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  checkPhase = ''
    ${python.interpreter} tests/downstream/integrate.py
  '';

  meta = {
    description = "Modern, extensible Python build backend";
    mainProgram = "hatchling";
    homepage = "https://hatch.pypa.io/latest/";
    changelog = "https://github.com/pypa/hatch/releases/tag/hatchling-v${finalAttrs.version}";
    license = lib.licenses.mit;

  };
})
