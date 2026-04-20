# ekaos test suite

{ pkgs ? import ../.. {} }:

{
  # Basic boot test
  simple = pkgs.ekaosTest ./simple.nix;

  # Service management test
  service = pkgs.ekaosTest ./service.nix;

  # Boot process test
  boot-process = pkgs.ekaosTest ./boot-process.nix;

  # Run all tests
  all = pkgs.runCommand "ekaos-all-tests" {
    tests = [
      (pkgs.ekaosTest ./simple.nix)
      (pkgs.ekaosTest ./service.nix)
      (pkgs.ekaosTest ./boot-process.nix)
    ];
  } ''
    echo "Running all ekaos tests..."
    for test in $tests; do
      echo "Running test: $test"
      if [ -f "$test/success" ]; then
        echo "  ✓ PASSED"
      else
        echo "  ✗ FAILED"
        exit 1
      fi
    done
    touch $out
  '';
}
