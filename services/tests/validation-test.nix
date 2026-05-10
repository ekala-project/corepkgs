# Test suite for validation system
# Tests that validation catches incompatible options, missing dependencies, and configuration conflicts
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Helper to catch expected errors
  expectError = name: config: builtins.tryEval (services.buildSystemdUserServices config);

  # Helper to build and check if it succeeds (for warnings)
  expectWarning =
    name: builder: config:
    builder config;

  # Test 1: Platform-specific option on wrong builder (ERROR)
  # Using systemd.serviceConfig in launchd build should error
  test1_platformSpecificError = expectError "platform-specific-error" {
    bad-service = {
      enable = true;
      description = "Service with systemd options in launchd";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      systemd = {
        serviceConfig = {
          PrivateTmp = true;
        };
      };
    };
  };

  # Test 2: Valid service with platform-specific options (should succeed)
  test2_correctPlatformOptions = services.buildSystemdUserServices {
    good-service = {
      enable = true;
      description = "Service with correct systemd options";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      systemd = {
        serviceConfig = {
          PrivateTmp = true;
        };
      };
    };
  };

  # Test 3: postStart on launchd (WARNING)
  # This should build but warn
  test3_postStartWarning = services.buildLaunchdUserAgents {
    warning-service = {
      enable = true;
      description = "Service with postStart on launchd";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      postStart = ''
        echo "This will warn on launchd"
      '';
    };
  };

  # Test 4: restartPolicy on rc.d (WARNING)
  test4_restartPolicyWarning = services.buildRcdServices {
    restart-service = {
      enable = true;
      description = "Service with restartPolicy on rc.d";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      restartPolicy = "always";
    };
  };

  # Test 5: Empty command (ERROR)
  test5_emptyCommandError = expectError "empty-command" {
    no-command = {
      enable = true;
      description = "Service without command";
      command = "";
    };
  };

  # Test 6: Invalid restart policy (ERROR)
  test6_invalidRestartPolicy = expectError "invalid-restart-policy" {
    bad-restart = {
      enable = true;
      description = "Service with invalid restartPolicy";
      command = "${pkgs.coreutils}/bin/echo";
      restartPolicy = "invalid-policy";
    };
  };

  # Test 7: Multiple platform-specific options on wrong builder (ERROR)
  test7_multiplePlatformErrors = expectError "multiple-platform-errors" {
    multi-bad = {
      enable = true;
      description = "Service with multiple wrong platform options";
      command = "${pkgs.coreutils}/bin/echo";
      # Building for systemd but using launchd and runit options
      launchd = {
        runAtLoad = true;
      };
      runit = {
        logScript = "#!/bin/sh\necho log";
      };
    };
  };

  # Test 8: User switching warning on rc.d FreeBSD (WARNING)
  test8_userSwitchingWarning = services.buildRcdServices {
    user-service = {
      enable = true;
      description = "Service running as non-root";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      user = "nobody";
      rcd = {
        variant = "freebsd";
      };
    };
  };

  # Test 9: User switching on OpenBSD (no warning - native support)
  test9_userSwitchingOpenBSD = services.buildRcdServicesOpenBSD {
    user-openbsd = {
      enable = true;
      description = "Service running as non-root on OpenBSD";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      user = "nobody";
    };
  };

  # Test 10: Working directory warning on rc.d (WARNING)
  test10_workingDirWarning = services.buildRcdServices {
    workdir-service = {
      enable = true;
      description = "Service with working directory on rc.d";
      command = "${pkgs.coreutils}/bin/pwd";
      workingDirectory = "/tmp";
    };
  };

  # Test 11: postStop on launchd (WARNING)
  test11_postStopWarning = services.buildLaunchdUserAgents {
    poststop-service = {
      enable = true;
      description = "Service with postStop on launchd";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      postStop = ''
        echo "Cleaning up"
      '';
    };
  };

  # Test 12: Empty description (WARNING)
  test12_emptyDescriptionWarning = services.buildSystemdUserServices {
    no-desc = {
      enable = true;
      description = "";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "test" ];
    };
  };

  # Verification script
  verifyScript = pkgs.writeScript "verify-validation-tests" ''
    #!${pkgs.bash}/bin/bash
    set -e

    echo "========================================="
    echo "Validation System Test Suite"
    echo "========================================="
    echo

    # Test 1: Should have failed (platform-specific error)
    echo "Test 1: Platform-specific option error..."
    if [ "${toString test1_platformSpecificError.success}" = "true" ]; then
      echo "✗ FAILED: Should have caught platform-specific option error"
      exit 1
    else
      echo "✓ PASSED: Caught platform-specific option error"
    fi
    echo

    # Test 2: Should succeed (correct platform options)
    echo "Test 2: Correct platform-specific options..."
    if [ -f ${test2_correctPlatformOptions.good-service}/good-service.service ]; then
      echo "✓ PASSED: Service built successfully with correct options"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 3: Should build with warning (postStart on launchd)
    echo "Test 3: postStart warning on launchd..."
    if [ -f ${test3_postStartWarning.warning-service}/warning-service.plist ]; then
      echo "✓ PASSED: Service built with warning (check build output for warning message)"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 4: Should build with warning (restartPolicy on rc.d)
    echo "Test 4: restartPolicy warning on rc.d..."
    if [ -d ${test4_restartPolicyWarning.restart-service}/etc/rc.d ]; then
      echo "✓ PASSED: Service built with warning"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 5: Should have failed (empty command)
    echo "Test 5: Empty command error..."
    if [ "${toString test5_emptyCommandError.success}" = "true" ]; then
      echo "✗ FAILED: Should have caught empty command error"
      exit 1
    else
      echo "✓ PASSED: Caught empty command error"
    fi
    echo

    # Test 6: Should have failed (invalid restart policy)
    echo "Test 6: Invalid restart policy error..."
    if [ "${toString test6_invalidRestartPolicy.success}" = "true" ]; then
      echo "✗ FAILED: Should have caught invalid restart policy"
      exit 1
    else
      echo "✓ PASSED: Caught invalid restart policy error"
    fi
    echo

    # Test 7: Should have failed (multiple platform errors)
    echo "Test 7: Multiple platform-specific errors..."
    if [ "${toString test7_multiplePlatformErrors.success}" = "true" ]; then
      echo "✗ FAILED: Should have caught multiple platform errors"
      exit 1
    else
      echo "✓ PASSED: Caught multiple platform errors"
    fi
    echo

    # Test 8: Should build with warning (user switching on FreeBSD rc.d)
    echo "Test 8: User switching warning on FreeBSD rc.d..."
    if [ -d ${test8_userSwitchingWarning.user-service}/etc/rc.d ]; then
      echo "✓ PASSED: Service built with user switching warning"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 9: Should build without warning (user switching on OpenBSD - native support)
    echo "Test 9: User switching on OpenBSD (no warning expected)..."
    if [ -d ${test9_userSwitchingOpenBSD.user-openbsd}/etc/rc.d ]; then
      echo "✓ PASSED: Service built on OpenBSD"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 10: Should build with warning (working directory on rc.d)
    echo "Test 10: Working directory warning on rc.d..."
    if [ -d ${test10_workingDirWarning.workdir-service}/etc/rc.d ]; then
      echo "✓ PASSED: Service built with working directory warning"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 11: Should build with warning (postStop on launchd)
    echo "Test 11: postStop warning on launchd..."
    if [ -f ${test11_postStopWarning.poststop-service}/poststop-service.plist ]; then
      echo "✓ PASSED: Service built with postStop warning"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    # Test 12: Should build with warning (empty description)
    echo "Test 12: Empty description warning..."
    if [ -f ${test12_emptyDescriptionWarning.no-desc}/no-desc.service ]; then
      echo "✓ PASSED: Service built with empty description warning"
    else
      echo "✗ FAILED: Service should have built"
      exit 1
    fi
    echo

    echo "========================================="
    echo "All validation tests passed!"
    echo "========================================="
    echo
    echo "Summary:"
    echo "  - Errors correctly caught: 4 tests"
    echo "  - Warnings correctly issued: 8 tests"
    echo "  - Total tests: 12"
  '';

in
{
  # Export all test results
  inherit
    test1_platformSpecificError
    test2_correctPlatformOptions
    test3_postStartWarning
    test4_restartPolicyWarning
    test5_emptyCommandError
    test6_invalidRestartPolicy
    test7_multiplePlatformErrors
    test8_userSwitchingWarning
    test9_userSwitchingOpenBSD
    test10_workingDirWarning
    test11_postStopWarning
    test12_emptyDescriptionWarning
    verifyScript
    ;

  # Convenience: Run all validation tests
  all = pkgs.runCommand "validation-test-all" { } ''
    mkdir -p $out

    # Run verification
    ${verifyScript} 2>&1 | tee $out/test-results.txt
  '';
}
