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

  # Meta test: Run all tests
  all = pkgs.runCommand "all-runit-tests" { } ''
    echo "Running all runit tests..." >&2

    # List of tests
    ${pkgs.coreutils}/bin/cat > $TMPDIR/tests <<EOF
    ${builtins.concatStringsSep "\n" [
      "${simple-http}"
      "${multi-service}"
      "${with-prestart}"
      "${with-environment}"
    ]}
    EOF

    # Verify all passed
    while read test; do
      if [ -f "$test/result" ]; then
        echo "✓ Test passed: $test" >&2
      else
        echo "✗ Test failed: $test" >&2
        exit 1
      fi
    done < $TMPDIR/tests

    echo "All runit tests passed!" >&2
    mkdir -p $out
    echo "success" > $out/result
  '';
}
