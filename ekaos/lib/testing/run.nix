# Build the test derivation that runs the test

{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    test = mkOption {
      type = types.package;
      internal = true;
      description = "Test derivation that runs the test";
    };
  };

  config = {
    test = pkgs.runCommand "vm-test-run-${config.name}" {
      inherit (config) meta passthru;

      requiredSystemFeatures = [ "kvm" "nixos-test" ];

      preferLocalBuild = true;
      allowSubstitutes = false;

    } ''
      mkdir -p $out

      # Run the test
      echo "Running ekaosTest: ${config.name}"
      echo "======================================"

      if ${config.driver}/bin/ekaos-test-driver 2>&1 | tee $out/test-output.log; then
        echo "======================================"
        echo "Test PASSED: ${config.name}"
        touch $out/success
      else
        echo "======================================"
        echo "Test FAILED: ${config.name}"
        touch $out/failure
        exit 1
      fi
    '';
  };
}
