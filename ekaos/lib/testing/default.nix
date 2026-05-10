# ekaosTest - Testing framework for ekaos systems
# Inspired by nixosTest from nixpkgs
#
# Usage:
#   pkgs.ekaosTest {
#     name = "my-test";
#     nodes.machine = { ... };  # ekaos configuration
#     testScript = '' ... '';    # Python test code
#   }

{ lib, pkgs, ... }:

let
  # Test module system modules
  testModules = [
    ./nodes.nix
    ./meta.nix
    ./testScript.nix
    ./driver.nix
    ./run.nix
  ];

  # Evaluate a test without building it
  # Returns the evaluated module system with test configuration
  evalTest =
    module:
    let
      eval = lib.evalModules {
        class = "ekaosTest";
        modules = testModules ++ [ module ];
        specialArgs = {
          inherit pkgs;
          # Add other special args as needed
        };
      };
    in
    eval;

  # Run a test (evaluate and build)
  # Returns a derivation that runs the test
  runTest =
    module:
    let
      eval = evalTest module;
    in
    eval.config.test;

in

{
  inherit evalTest runTest;

  # Legacy compatibility (similar to nixpkgs makeTest)
  makeTest = runTest;
}
