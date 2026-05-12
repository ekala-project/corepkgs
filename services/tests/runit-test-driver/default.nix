# runit-test-driver - Python test driver for runitTests
#
# Provides Python test bindings similar to nixosTests/ekaosTests,
# but adapted for local sandbox execution with runit supervision.

{
  lib,
  python3,
}:

python3.pkgs.buildPythonPackage {
  pname = "runit-test-driver";
  version = "0.1.0";

  src = ./.;

  format = "setuptools";

  # No external dependencies needed - uses stdlib
  propagatedBuildInputs = [ ];

  # Type checking with mypy (optional, can be disabled in tests)
  nativeCheckInputs = with python3.pkgs; [
    mypy
    pytestCheckHook
  ];

  # Don't run tests during package build (tests run via nix-build)
  doCheck = false;

  meta = {
    description = "Python test driver for runitTests";
    maintainers = [ ];
  };
}
