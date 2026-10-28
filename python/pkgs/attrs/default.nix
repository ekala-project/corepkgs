{
  lib,
  callPackage,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  replaceVars,
  hatchling,
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

  outputs = [
    "out"
    "testout"
  ];

  postInstall = ''
    # Install tests as the tests output.
    mkdir $testout
    cp -R tests $testout
  '';

  pythonImportsCheck = [ "attr" ];

  passthru.tests = {
    pytest = callPackage ./tests.nix { };
  };

  meta = {
    description = "Python attributes without boilerplate";
    homepage = "https://github.com/python-attrs/attrs";
    changelog = "https://github.com/python-attrs/attrs/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
