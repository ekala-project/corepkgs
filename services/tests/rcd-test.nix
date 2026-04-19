# Test suite for BSD rc.d services
# Verifies that rc.d scripts are generated correctly for different BSD variants
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Test 1: Basic FreeBSD rc.d service
  basicFreeBSDService = services.buildRcdServices {
    basic-test = {
      enable = true;
      description = "Basic FreeBSD rc.d Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      rcd = {
        variant = "freebsd";
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 2: OpenBSD rc.d service
  basicOpenBSDService = services.buildRcdServicesOpenBSD {
    basic-test = {
      enable = true;
      description = "Basic OpenBSD rc.d Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
    };
  };

  # Test 3: Service with environment variables
  envService = services.buildRcdServices {
    env-test = {
      enable = true;
      description = "Environment Test Service";
      command = "${pkgs.python3}/bin/python3";
      args = [
        "-c"
        "import os; print(os.environ.get('TEST_VAR'))"
      ];
      environment = {
        TEST_VAR = "test_value";
        PYTHONUNBUFFERED = "1";
      };
      rcd = {
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 4: Service with network dependencies
  networkService = services.buildRcdServices {
    network-test = {
      enable = true;
      description = "Network Service Test";
      command = "${pkgs.python3}/bin/python3";
      args = [
        "-m"
        "http.server"
        "8080"
      ];
      rcd = {
        rcRequire = [
          "DAEMON"
          "NETWORKING"
        ];
        rcBefore = [ "LOGIN" ];
        rcKeywords = [ "shutdown" ];
        pidfile = "/var/run/network-test.pid";
      };
    };
  };

  # Test 5: Service with preStart hook
  preStartService = services.buildRcdServices {
    prestart-test = {
      enable = true;
      description = "PreStart Test Service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "main" ];
      preStart = ''
        echo "Setting up..."
        mkdir -p /tmp/test-service
      '';
      rcd = {
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 6: Service with postStop hook
  postStopService = services.buildRcdServices {
    poststop-test = {
      enable = true;
      description = "PostStop Test Service";
      command = "${pkgs.coreutils}/bin/sleep";
      args = [ "infinity" ];
      postStop = ''
        echo "Cleaning up..."
        rm -rf /tmp/test-service
      '';
      rcd = {
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 7: Service with working directory
  workingDirService = services.buildRcdServices {
    workdir-test = {
      enable = true;
      description = "Working Directory Test";
      command = "${pkgs.coreutils}/bin/pwd";
      workingDirectory = "/tmp";
      rcd = {
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 8: Service with PATH
  pathService = services.buildRcdServices {
    path-test = {
      enable = true;
      description = "PATH Test Service";
      command = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        "echo $PATH"
      ];
      path = with pkgs; [
        coreutils
        findutils
      ];
      rcd = {
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 9: Service with extra rc.d script code
  extraScriptService = services.buildRcdServices {
    extra-test = {
      enable = true;
      description = "Extra Script Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "test" ];
      rcd = {
        rcRequire = [ "DAEMON" ];
        extraRcScript = ''
          # Custom reload signal
          sig_reload="USR1"

          # Custom stop command
          stop_cmd="''${name}_custom_stop"
          extra_test_custom_stop() {
              echo "Custom stop logic"
          }
        '';
      };
    };
  };

  # Test 10: Service with extra rc.conf entries
  extraRcConfService = services.buildRcdServices {
    rcconf-test = {
      enable = true;
      description = "Extra rc.conf Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "test" ];
      rcd = {
        rcRequire = [ "DAEMON" ];
        extraRcConf = ''
          # Custom flags
          rcconf_test_flags="-v -d"

          # Custom timeout
          rcconf_test_timeout="30"
        '';
      };
    };
  };

  # Test 11: NetBSD variant service
  netbsdService = services.buildRcdServices {
    netbsd-test = {
      enable = true;
      description = "NetBSD rc.d Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "netbsd" ];
      rcd = {
        variant = "netbsd";
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Test 12: DragonFly BSD variant service
  dragonflyService = services.buildRcdServices {
    dragonfly-test = {
      enable = true;
      description = "DragonFly BSD rc.d Test";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "dragonfly" ];
      rcd = {
        variant = "dragonfly";
        rcRequire = [ "DAEMON" ];
      };
    };
  };

  # Build verification script
  verifyScript = pkgs.writeScript "verify-rcd-tests" ''
    #!${pkgs.bash}/bin/bash
    set -e

    echo "========================================="
    echo "BSD rc.d Test Suite Verification"
    echo "========================================="
    echo

    # Test 1: FreeBSD service exists and is executable
    echo "Test 1: Basic FreeBSD service..."
    test -f ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    test -x ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "#!/bin/sh" ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "PROVIDE:" ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "REQUIRE: DAEMON" ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    grep -q 'name="basic-test"' ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "command=" ${basicFreeBSDService.basic-test}/etc/rc.d/basic-test
    echo "✓ FreeBSD service generated correctly"
    echo

    # Test 2: OpenBSD service exists and uses OpenBSD syntax
    echo "Test 2: Basic OpenBSD service..."
    test -f ${basicOpenBSDService.basic-test}/etc/rc.d/basic-test
    test -x ${basicOpenBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "#!/bin/ksh" ${basicOpenBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "daemon=" ${basicOpenBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "rc.subr" ${basicOpenBSDService.basic-test}/etc/rc.d/basic-test
    grep -q "rc_cmd" ${basicOpenBSDService.basic-test}/etc/rc.d/basic-test
    echo "✓ OpenBSD service generated correctly"
    echo

    # Test 3: Environment variables present
    echo "Test 3: Environment variables..."
    grep -q "TEST_VAR=" ${envService.env-test}/etc/rc.d/env-test
    grep -q "PYTHONUNBUFFERED=" ${envService.env-test}/etc/rc.d/env-test
    echo "✓ Environment variables included"
    echo

    # Test 4: Network dependencies
    echo "Test 4: Network dependencies..."
    grep -q "REQUIRE:.*NETWORKING" ${networkService.network-test}/etc/rc.d/network-test
    grep -q "BEFORE: LOGIN" ${networkService.network-test}/etc/rc.d/network-test
    grep -q 'pidfile="/var/run/network-test.pid"' ${networkService.network-test}/etc/rc.d/network-test
    echo "✓ Network dependencies configured"
    echo

    # Test 5: preStart hook
    echo "Test 5: preStart hook..."
    grep -q "Setting up" ${preStartService.prestart-test}/etc/rc.d/prestart-test
    grep -q "mkdir -p" ${preStartService.prestart-test}/etc/rc.d/prestart-test
    echo "✓ preStart hook included"
    echo

    # Test 6: postStop hook
    echo "Test 6: postStop hook..."
    grep -q "Cleaning up" ${postStopService.poststop-test}/etc/rc.d/poststop-test
    grep -q "rm -rf" ${postStopService.poststop-test}/etc/rc.d/poststop-test
    echo "✓ postStop hook included"
    echo

    # Test 7: Working directory
    echo "Test 7: Working directory..."
    grep -q 'cd /tmp' ${workingDirService.workdir-test}/etc/rc.d/workdir-test
    echo "✓ Working directory configured"
    echo

    # Test 8: PATH configuration
    echo "Test 8: PATH configuration..."
    grep -q "PATH=" ${pathService.path-test}/etc/rc.d/path-test
    echo "✓ PATH configured"
    echo

    # Test 9: Extra script code
    echo "Test 9: Extra rc.d script..."
    grep -q "sig_reload=" ${extraScriptService.extra-test}/etc/rc.d/extra-test
    grep -q "extra_test_custom_stop" ${extraScriptService.extra-test}/etc/rc.d/extra-test
    echo "✓ Extra script code included"
    echo

    # Test 10: rc.conf sample exists
    echo "Test 10: rc.conf sample..."
    test -f ${extraRcConfService.rcconf-test}/etc/rc.conf.d/rcconf-test.sample
    grep -q "rcconf_test_flags" ${extraRcConfService.rcconf-test}/etc/rc.conf.d/rcconf-test.sample
    echo "✓ rc.conf sample generated"
    echo

    echo "========================================="
    echo "All tests passed!"
    echo "========================================="
  '';

in
{
  # Export all test services
  inherit
    basicFreeBSDService
    basicOpenBSDService
    envService
    networkService
    preStartService
    postStopService
    workingDirService
    pathService
    extraScriptService
    extraRcConfService
    netbsdService
    dragonflyService
    verifyScript
    ;

  # Convenience: build all tests together
  all = pkgs.runCommand "rcd-test-all" { } ''
    mkdir -p $out

    # Copy all test outputs
    cp -r ${basicFreeBSDService.basic-test}/etc $out/basic-freebsd
    cp -r ${basicOpenBSDService.basic-test}/etc $out/basic-openbsd
    cp -r ${envService.env-test}/etc $out/env
    cp -r ${networkService.network-test}/etc $out/network
    cp -r ${preStartService.prestart-test}/etc $out/prestart
    cp -r ${postStopService.poststop-test}/etc $out/poststop
    cp -r ${workingDirService.workdir-test}/etc $out/workdir
    cp -r ${pathService.path-test}/etc $out/path
    cp -r ${extraScriptService.extra-test}/etc $out/extra
    cp -r ${extraRcConfService.rcconf-test}/etc $out/rcconf
    cp -r ${netbsdService.netbsd-test}/etc $out/netbsd
    cp -r ${dragonflyService.dragonfly-test}/etc $out/dragonfly

    # Run verification
    ${verifyScript} 2>&1 | tee $out/test-results.txt
  '';
}
