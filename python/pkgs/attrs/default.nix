{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  replaceVars,
  hatchling,
  hypothesis,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "attrs";
  version = "26.1.0";
  disabled = pythonOlder "3.7";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-0DzricsyKo/XBtT7kZQHN7ZkKqNpmP4TCpvJbJhe/zI=";
  };

  patches = [
    (replaceVars ./remove-hatch-plugins.patch {
      # hatch-vcs and hatch-fancy-pypi-readme depend on pytest, which depends on attrs
      inherit (finalAttrs) version;
    })
  ];

  nativeBuildInputs = [ hatchling ];

  testPaths = [ "tests" ];

  nativeTestOnlyCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  pythonImportsCheck = [ "attr" ];

  meta = {
    description = "Python attributes without boilerplate";
    homepage = "https://github.com/python-attrs/attrs";
    changelog = "https://github.com/python-attrs/attrs/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
