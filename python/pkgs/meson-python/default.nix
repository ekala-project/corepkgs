{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,

  pythonOlder,

  # build-system, dependencies
  meson,
  ninja,
  pyproject-metadata,
  tomli,

  # tests
  cython,
  gitMinimal,
  pytestCheckHook,
  pytest-mock,
}:

buildPythonPackage rec {
  pname = "meson-python";
  version = "0.22.0";
  pyproject = true;

  src = fetchPypi {
    inherit version;
    pname = "meson_python";
    hash = "sha256-nIGdDU76dG7a36rkZjwOnHVlkYbvflurEjML/iKWTfw=";
  };

  build-system = [
    meson
    ninja
    pyproject-metadata
  ]
  ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  dependencies = [
    meson
    ninja
    pyproject-metadata
  ]
  ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  nativeCheckInputs = [
    cython
    gitMinimal
    pytestCheckHook
    pytest-mock
  ];

  # meson-python respectes MACOSX_DEPLOYMENT_TARGET, but compares it with the
  # actual platform version during tests, which mismatches.
  # https://github.com/mesonbuild/meson-python/issues/760
  preCheck =
    if stdenv.hostPlatform.isDarwin then
      ''
        unset MACOSX_DEPLOYMENT_TARGET
      ''
    else
      null;

  # TODO(corepkgs): move to passthru tests
  doCheck = false;
  setupHooks = [ ./add-build-flags.sh ];

  pythonImportsCheck = [ "mesonpy" ];

  meta = {
    changelog = "https://github.com/mesonbuild/meson-python/blob/${version}/CHANGELOG.rst";
    description = "Meson Python build backend (PEP 517)";
    homepage = "https://github.com/mesonbuild/meson-python";
    license = [ lib.licenses.mit ];
  };
}
