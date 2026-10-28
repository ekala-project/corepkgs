{
  lib,
  buildPythonPackage,
  fetchPypi,
  flit-core,
  pyproject-hooks,
  pytestCheckHook,
  pythonOlder,
  setuptools,
  testpath,
  tomli,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyproject-hooks";
  version = "1.2.0";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    pname = "pyproject_hooks";
    inherit (finalAttrs) version;
    hash = "sha256-HoWb1cQPrpRIZC3Yca30WeXiCEGG6NLCp5qCTJcNofg=";
  };

  nativeBuildInputs = [ flit-core ];

  propagatedBuildInputs = lib.optionals (pythonOlder "3.11") [ tomli ];

  passthru.tests = {
    pytest = buildPythonPackage {
      pname = "${finalAttrs.pname}-pytest";
      inherit (finalAttrs) version;
      pyproject = false;

      dontBuild = true;
      dontInstall = true;

      nativeCheckInputs = [
        pyproject-hooks
        pytestCheckHook
        setuptools
        testpath
      ];

      disabledTests = [
        # fail to import setuptools
        "test_setup_py"
        "test_issue_104"
      ];
    };
  };

  pythonImportsCheck = [ "pyproject_hooks" ];

  meta = {
    description = "Low-level library for calling build-backends in `pyproject.toml`-based project";
    homepage = "https://github.com/pypa/pyproject-hooks";
    changelog = "https://github.com/pypa/pyproject-hooks/blob/v${finalAttrs.version}/docs/changelog.rst";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
