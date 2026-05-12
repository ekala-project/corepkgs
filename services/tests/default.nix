# Example runit service tests
#
# These tests demonstrate module-based service testing using the unified
# services module system. Services are defined using services.* options
# just like in ekaos/NixOS configurations.
#
# Each test is defined in its own file in runit/test/ for better organization.

{
  pkgs ? import ../../. { },
}:

let
  runitTestsLib = pkgs.callPackage ./runit-tests.nix { };
  inherit (runitTestsLib) mkRunitTest;

  # Helper to call mkRunitTest with test file that expects pkgs
  callTest = testFile: mkRunitTest (pkgs.callPackage testFile { });

in

rec {
  # Test 1: Simple HTTP server smoke test
  simple-http = callTest ./runit/test/simple-http.nix;

  # Test 2: Multi-service interaction
  multi-service = callTest ./runit/test/multi-service.nix;

  # Test 3: Service with preStart hook
  with-prestart = callTest ./runit/test/with-prestart.nix;

  # Test 4: Service environment variables
  with-environment = callTest ./runit/test/with-environment.nix;
}
