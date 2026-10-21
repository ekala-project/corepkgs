{
  lib,
  buildPythonPackage,
  dunamai,
  fetchFromGitHub,
  jinja2,
  poetry-core,
  pytestCheckHook,
  pythonOlder,
  tomlkit,
}:

buildPythonPackage (finalAttrs: {
  pname = "poetry-dynamic-versioning";
  version = "1.10.1";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "mtkennerly";
    repo = "poetry-dynamic-versioning";
    tag = "v${finalAttrs.version}";
    hash = "sha256-M9JduX1oeaDVDZXPKst77xUWgEcxcrL+CstCBH49M/Y=";
  };

  nativeBuildInputs = [ poetry-core ];

  propagatedBuildInputs = [
    dunamai
    jinja2
    tomlkit
  ];

  # Takes a long time
  nativeCheckInputs = [
    pytestCheckHook
  ];

  disabledTests = [
    # these require .git, but leaveDotGit = true doesn't help
    "test__get_version__defaults"
    "test__get_version__format_jinja"
    # these expect to be able to run the poetry cli which fails in test hook
    "test_integration"
  ];

  pythonImportsCheck = [ "poetry_dynamic_versioning" ];

  setupHook = ./setup-hook.sh;

  meta = {
    description = "Plugin for Poetry to enable dynamic versioning based on VCS tags";
    mainProgram = "poetry-dynamic-versioning";
    homepage = "https://github.com/mtkennerly/poetry-dynamic-versioning";
    changelog = "https://github.com/mtkennerly/poetry-dynamic-versioning/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;

  };
})
