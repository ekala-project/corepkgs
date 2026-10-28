{
  lib,
  buildPythonPackage,
  pythonAtLeast,
  fetchFromGitHub,
  pytestCheckHook,
  flit-core,
  installer,
  mock,
}:

buildPythonPackage (finalAttrs: {
  pname = "installer";
  version = "0.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pypa";
    repo = "installer";
    tag = finalAttrs.version;
    hash = "sha256-thHghU+1Alpay5r9Dc3v7ATRFfYKV8l9qR0nbGOOX/A=";
  };

  patches = lib.optionals (pythonAtLeast "3.13") [
    # Fix compatibility with Python 3.13
    # https://github.com/pypa/installer/pull/201
    ./python313-compat.patch
  ];

  nativeBuildInputs = [ flit-core ];

  passthru.tests = {
    pytest = buildPythonPackage {
      pname = "${finalAttrs.pname}-pytest";
      inherit (finalAttrs) version;
      pyproject = false;

      dontBuild = true;
      dontInstall = true;

      nativeCheckInputs = [
        installer
        mock
        pytestCheckHook
      ];
    };
  };

  pythonImportsCheck = [ "installer" ];

  meta = {
    description = "Low-level library for installing a Python package from a wheel distribution";
    homepage = "https://github.com/pypa/installer";
    changelog = "https://github.com/pypa/installer/blob/${finalAttrs.src.rev}/docs/changelog.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
