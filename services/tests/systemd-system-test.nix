# Test suite for systemd system services
# Verifies that system services are generated correctly
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Test 1: Basic system service
  basicSystemService = services.buildSystemdSystemServices {
    basic-test = {
      enable = true;
      description = "Basic System Service Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      restartPolicy = "on-failure";
    };
  };

  # Test 2: System service with network dependencies
  networkSystemService = services.buildSystemdSystemServices {
    network-test = {
      enable = true;
      description = "Network System Service";
      command = "${pkgs.python3}/bin/python3";
      args = [
        "-m"
        "http.server"
        "8080"
      ];
      systemd = {
        wants = [ "network-online.target" ];
        after = [
          "network.target"
          "network-online.target"
        ];
      };
    };
  };

  # Test 3: Custom wantedBy target (should override default)
  customWantedByService = services.buildSystemdSystemServices {
    custom-target = {
      enable = true;
      description = "Custom WantedBy Test";
      command = "${pkgs.coreutils}/bin/true";
      systemd = {
        wantedBy = [ "graphical.target" ];
      };
    };
  };

  # Test 4: Non-root user service
  nonRootService = services.buildSystemdSystemServices {
    nonroot-test = {
      enable = true;
      description = "Non-Root User Service";
      command = "${pkgs.coreutils}/bin/sleep";
      args = [ "infinity" ];
      user = "nobody";
      group = "nobody";
      systemd = {
        serviceConfig = {
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    };
  };

  # Test 5: Service with preStart hook
  preStartService = services.buildSystemdSystemServices {
    prestart-test = {
      enable = true;
      description = "PreStart Test Service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "main" ];
      preStart = ''
        echo "Setting up..."
        mkdir -p /tmp/test-service
      '';
      postStop = ''
        echo "Cleaning up..."
        rm -rf /tmp/test-service
      '';
    };
  };

  # Test 6: Service with environment variables
  envService = services.buildSystemdSystemServices {
    env-test = {
      enable = true;
      description = "Environment Test Service";
      command = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        "env | grep -E '(MY_VAR|MY_PATH)'"
      ];
      environment = {
        MY_VAR = "test-value";
        MY_PATH = "/custom/path";
      };
      path = with pkgs; [
        coreutils
        gnugrep
      ];
    };
  };

  # Test 7: Always restart service
  alwaysRestartService = services.buildSystemdSystemServices {
    always-restart = {
      enable = true;
      description = "Always Restart Service";
      command = "${pkgs.coreutils}/bin/true";
      restartPolicy = "always";
      systemd = {
        serviceConfig = {
          RestartSec = "5s";
        };
      };
    };
  };

  # Test 8: System service with requires dependency
  requiresService = services.buildSystemdSystemServices {
    requires-test = {
      enable = true;
      description = "Requires Dependency Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "test" ];
      systemd = {
        requires = [ "network.target" ];
        after = [ "network.target" ];
      };
    };
  };

  # Test 9: Compare user vs system (same config)
  compareConfig = {
    compare-test = {
      enable = true;
      description = "User vs System Comparison";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "compare" ];
      # Use default wantedBy to see auto-adjustment
    };
  };

  userVersionCompare = services.buildSystemdUserServices compareConfig;
  systemVersionCompare = services.buildSystemdSystemServices compareConfig;

in
{
  # Individual test outputs
  inherit
    basicSystemService
    networkSystemService
    customWantedByService
    nonRootService
    preStartService
    envService
    alwaysRestartService
    requiresService
    ;

  # Comparison test
  inherit
    userVersionCompare
    systemVersionCompare
    ;

  # Combined test output for easy inspection
  all = pkgs.runCommand "systemd-system-tests" { } ''
    mkdir -p $out

    echo "=== Test 1: Basic System Service ===" > $out/test-results.txt
    cat ${basicSystemService.basic-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 2: Network System Service ===" >> $out/test-results.txt
    cat ${networkSystemService.network-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 3: Custom WantedBy ===" >> $out/test-results.txt
    cat ${customWantedByService.custom-target} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 4: Non-Root Service ===" >> $out/test-results.txt
    cat ${nonRootService.nonroot-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 5: PreStart Service ===" >> $out/test-results.txt
    cat ${preStartService.prestart-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 6: Environment Service ===" >> $out/test-results.txt
    cat ${envService.env-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 7: Always Restart ===" >> $out/test-results.txt
    cat ${alwaysRestartService.always-restart} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 8: Requires Dependency ===" >> $out/test-results.txt
    cat ${requiresService.requires-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Test 9: User vs System Comparison ===" >> $out/test-results.txt
    echo "--- User Service ---" >> $out/test-results.txt
    cat ${userVersionCompare.compare-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt
    echo "--- System Service ---" >> $out/test-results.txt
    cat ${systemVersionCompare.compare-test} >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    # Verification checks
    echo "=== Verification Checks ===" >> $out/test-results.txt

    # Check 1: System service should have multi-user.target by default
    if grep -q "WantedBy=multi-user.target" ${basicSystemService.basic-test}; then
      echo "✓ Basic service has multi-user.target" >> $out/test-results.txt
    else
      echo "✗ Basic service missing multi-user.target" >> $out/test-results.txt
    fi

    # Check 2: Custom wantedBy should override default
    if grep -q "WantedBy=graphical.target" ${customWantedByService.custom-target}; then
      echo "✓ Custom wantedBy overrides default" >> $out/test-results.txt
    else
      echo "✗ Custom wantedBy not working" >> $out/test-results.txt
    fi

    # Check 3: Non-root service should have User= line
    if grep -q "User=nobody" ${nonRootService.nonroot-test}; then
      echo "✓ Non-root service has User= directive" >> $out/test-results.txt
    else
      echo "✗ Non-root service missing User= directive" >> $out/test-results.txt
    fi

    # Check 4: Compare user vs system default targets
    if grep -q "WantedBy=default.target" ${userVersionCompare.compare-test}; then
      echo "✓ User service has default.target" >> $out/test-results.txt
    else
      echo "✗ User service missing default.target" >> $out/test-results.txt
    fi

    if grep -q "WantedBy=multi-user.target" ${systemVersionCompare.compare-test}; then
      echo "✓ System service has multi-user.target" >> $out/test-results.txt
    else
      echo "✗ System service missing multi-user.target" >> $out/test-results.txt
    fi

    # Check 5: Network dependencies
    if grep -q "After=network.target" ${networkSystemService.network-test}; then
      echo "✓ Network service has After= dependency" >> $out/test-results.txt
    else
      echo "✗ Network service missing After= dependency" >> $out/test-results.txt
    fi

    # Check 6: Restart policies
    if grep -q "Restart=always" ${alwaysRestartService.always-restart}; then
      echo "✓ Always restart policy working" >> $out/test-results.txt
    else
      echo "✗ Always restart policy not applied" >> $out/test-results.txt
    fi

    echo "" >> $out/test-results.txt
    echo "Test suite complete. Check test-results.txt for details." >> $out/test-results.txt

    # Copy individual service files for inspection
    cp ${basicSystemService.basic-test} $out/basic-test.service
    cp ${networkSystemService.network-test} $out/network-test.service
    cp ${customWantedByService.custom-target} $out/custom-target.service
    cp ${nonRootService.nonroot-test} $out/nonroot-test.service
    cp ${userVersionCompare.compare-test} $out/compare-user.service
    cp ${systemVersionCompare.compare-test} $out/compare-system.service
  '';
}

# Usage:
#
# Run all tests:
#   nix-build services/tests/systemd-system-test.nix -A all
#   cat result/test-results.txt
#
# Inspect individual test:
#   nix-build services/tests/systemd-system-test.nix -A basicSystemService
#   cat result/basic-test.service
#
# Compare user vs system:
#   nix-build services/tests/systemd-system-test.nix -A userVersionCompare
#   nix-build services/tests/systemd-system-test.nix -A systemVersionCompare
#   diff result-userVersionCompare/compare-test.service \
#        result-systemVersionCompare/compare-test.service
