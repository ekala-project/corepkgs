{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  poetry-core,

  # dependencies
  packaging,

  # tests
  addBinToPathHook,
  gitMinimal,
  pytestCheckHook,
  writableTmpDirAsHomeHook,
}:

buildPythonPackage rec {
  pname = "dunamai";
  version = "1.26.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mtkennerly";
    repo = "dunamai";
    tag = "v${version}";
    hash = "sha256-PKIJTkzKQ17wEp6AH/KldDyjtoGo0qU1RHzVaZCPLTU=";
  };

  build-system = [ poetry-core ];

  dependencies = [ packaging ];

  # Takes a long while
  doCheck = false;

  preCheck = ''
    git config --global user.email "nobody@example.com"
    git config --global user.name "Nobody"
  '';

  nativeCheckInputs = [
    addBinToPathHook
    gitMinimal
    pytestCheckHook
    writableTmpDirAsHomeHook
  ];

  disabledTests = [
    # clones from github.com
    "test__version__from_git__shallow"
  ];

  pythonImportsCheck = [ "dunamai" ];

  meta = {
    description = "Dynamic version generation";
    mainProgram = "dunamai";
    homepage = "https://github.com/mtkennerly/dunamai";
    changelog = "https://github.com/mtkennerly/dunamai/blob/${src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;

  };
}
