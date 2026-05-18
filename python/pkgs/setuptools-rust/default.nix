{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  rustPlatform,
  rustc,
  cargo,
  semantic-version,
  setuptools,
  setuptools-scm,
  replaceVars,
  python,
  targetPackages,
}:
buildPythonPackage rec {
  pname = "setuptools-rust";
  version = "1.12.1";
  pyproject = true;

  src = fetchPypi {
    pname = "setuptools_rust";
    inherit version;
    hash = "sha256-ha5wmJ2Wyc/rXvec87rC1SALxVZPcgoG7c7tvfZmRkA=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    semantic-version
    setuptools
  ];

  pythonImportsCheck = [ "setuptools_rust" ];

  doCheck = false;

  # integrate the setup hook to set up the build environment for cross compilation
  # this hook is automatically propagated to consumers using setuptools-rust as build-system
  #
  # Only include the setup hook if python.pythonOnTargetForTarget is not empty.
  # python.pythonOnTargetForTarget is not always available, for example in
  # pkgsLLVM.python3.pythonOnTargetForTarget. cross build with pkgsLLVM should not be affected.
  setupHook =
    if !(python ? pythonOnTargetForTarget) || python.pythonOnTargetForTarget == { } then
      null
    else
      replaceVars ./setuptools-rust-hook.sh {
        pyLibDir = "${python.pythonOnTargetForTarget}/lib/${python.pythonOnTargetForTarget.libPrefix}";
        cargoBuildTarget = stdenv.targetPlatform.rust.rustcTargetSpec;
        cargoLinkerVar = stdenv.targetPlatform.rust.cargoEnvVarTarget;
        targetLinker = "${targetPackages.stdenv.cc}/bin/${targetPackages.stdenv.cc.targetPrefix}cc";
      };

  meta = {
    description = "Setuptools plugin for Rust support";
    homepage = "https://github.com/PyO3/setuptools-rust";
    changelog = "https://github.com/PyO3/setuptools-rust/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
