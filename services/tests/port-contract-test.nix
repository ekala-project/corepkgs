# Test suite for port contracts
# Tests port collision detection, contract consistency, Docker auto-derivation,
# and backward compatibility
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Helper to catch expected errors
  expectError = name: config: builtins.tryEval (services.buildSystemdUserServices config);

  # Test 1: Service with valid port contracts builds successfully
  test1_validPortContracts = services.buildSystemdUserServices {
    web-app = {
      enable = true;
      description = "Web application";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      ports = {
        http = {
          port = 8080;
          hostname = "app.example.com";
        };
        metrics = {
          port = 9090;
          internal = true;
        };
      };
    };
  };

  # Test 2: Port collision detection — two services claiming same port/protocol
  test2_portCollision = expectError "port-collision" {
    service-a = {
      enable = true;
      description = "Service A";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "a" ];
      ports.http = {
        port = 8080;
      };
    };
    service-b = {
      enable = true;
      description = "Service B";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "b" ];
      ports.http = {
        port = 8080;
      };
    };
  };

  # Test 3: Same port, different protocols — no collision
  test3_differentProtocols = services.buildSystemdUserServices {
    tcp-service = {
      enable = true;
      description = "TCP service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "tcp" ];
      ports.main = {
        port = 53;
        protocol = "tcp";
      };
    };
    udp-service = {
      enable = true;
      description = "UDP service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "udp" ];
      ports.main = {
        port = 53;
        protocol = "udp";
      };
    };
  };

  # Test 4: Contract data preservation — values accessible after eval
  test4_dataPreservation =
    let
      contracts = services.getPortContracts {
        myapp = {
          enable = true;
          description = "My app";
          command = "${pkgs.coreutils}/bin/echo";
          ports = {
            http = {
              port = 8080;
              hostname = "myapp.example.com";
              path = "/api";
              transport = "http2";
              tls = {
                acme = true;
                forceRedirect = true;
              };
              healthCheck = {
                path = "/health";
                interval = 10;
              };
            };
            grpc = {
              port = 9000;
              transport = "grpc";
              internal = true;
            };
          };
        };
      };
      httpContract = builtins.head (builtins.filter (c: c.portName == "http") contracts);
      grpcContract = builtins.head (builtins.filter (c: c.portName == "grpc") contracts);
    in
    {
      contractCount = builtins.length contracts;
      httpPort = httpContract.port;
      httpHostname = httpContract.hostname;
      httpPath = httpContract.path;
      httpTransport = httpContract.transport;
      httpAcme = httpContract.tls.acme;
      httpHealthPath = httpContract.healthCheck.path;
      httpHealthInterval = httpContract.healthCheck.interval;
      grpcPort = grpcContract.port;
      grpcInternal = grpcContract.internal;
    };

  # Test 5: Backward compatibility — services without port declarations still work
  test5_backwardCompat = services.buildSystemdUserServices {
    legacy-service = {
      enable = true;
      description = "Legacy service with no port contracts";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "hello" ];
      # No ports declared — should work fine
    };
  };

  # Test 6: Port contracts with tls.acme but no hostname — consistency error
  test6_acmeNoHostname = expectError "acme-no-hostname" {
    bad-acme = {
      enable = true;
      description = "Service with ACME but no hostname";
      command = "${pkgs.coreutils}/bin/echo";
      ports.http = {
        port = 8080;
        tls.acme = true;
        # hostname is null — should error
      };
    };
  };

  # Test 7: openFirewall + internal contradiction — warning but builds
  test7_firewallInternalWarning = services.buildSystemdUserServices {
    contradictory = {
      enable = true;
      description = "Service with contradictory port options";
      command = "${pkgs.coreutils}/bin/echo";
      ports.http = {
        port = 8080;
        openFirewall = true;
        internal = true;
      };
    };
  };

  # Test 8: checkPortContracts utility — collision detection without building
  test8_checkUtilityCollision = builtins.tryEval (
    services.checkPortContracts {
      svc1 = {
        enable = true;
        description = "Service 1";
        command = "${pkgs.coreutils}/bin/echo";
        ports.web = {
          port = 3000;
        };
      };
      svc2 = {
        enable = true;
        description = "Service 2";
        command = "${pkgs.coreutils}/bin/echo";
        ports.web = {
          port = 3000;
        };
      };
    }
  );

  # Test 9: checkPortContracts utility — no collision returns true
  test9_checkUtilityOk = services.checkPortContracts {
    svc1 = {
      enable = true;
      description = "Service 1";
      command = "${pkgs.coreutils}/bin/echo";
      ports.web = {
        port = 3000;
      };
    };
    svc2 = {
      enable = true;
      description = "Service 2";
      command = "${pkgs.coreutils}/bin/echo";
      ports.web = {
        port = 3001;
      };
    };
  };

  # Test 10: Multiple ports on same service — no self-collision
  test10_multiPortSameService = services.buildSystemdUserServices {
    multi-port = {
      enable = true;
      description = "Multi-port service";
      command = "${pkgs.coreutils}/bin/echo";
      ports = {
        http = {
          port = 8080;
        };
        https = {
          port = 8443;
          tls.enable = true;
        };
        metrics = {
          port = 9090;
          internal = true;
        };
      };
    };
  };

  # Test 11: Disabled service ports don't cause collisions
  test11_disabledServiceNoCollision = services.buildSystemdUserServices {
    active = {
      enable = true;
      description = "Active service";
      command = "${pkgs.coreutils}/bin/echo";
      ports.http = {
        port = 8080;
      };
    };
    inactive = {
      enable = false;
      description = "Inactive service on same port";
      command = "${pkgs.coreutils}/bin/echo";
      ports.http = {
        port = 8080;
      };
    };
  };

  # Verification script
  verifyScript = pkgs.writeScript "verify-port-contract-tests" ''
    #!${pkgs.bash}/bin/bash
    set -e
    passed=0
    failed=0

    pass() { echo "  ✓ $1"; passed=$((passed + 1)); }
    fail() { echo "  ✗ $1"; failed=$((failed + 1)); }

    echo "========================================="
    echo "Port Contract Test Suite"
    echo "========================================="
    echo

    # Test 1: Valid port contracts
    echo "Test 1: Valid port contracts build successfully..."
    if [ -f ${test1_validPortContracts.web-app}/web-app.service ]; then
      pass "Service with port contracts built"
    else
      fail "Service should have built"
    fi

    # Test 2: Port collision detected
    echo "Test 2: Port collision detection..."
    if [ "${toString test2_portCollision.success}" = "1" ]; then
      fail "Should have detected port collision"
    else
      pass "Port collision detected and build blocked"
    fi

    # Test 3: Different protocols, same port — no collision
    echo "Test 3: Same port, different protocols..."
    if [ -f ${test3_differentProtocols.tcp-service}/tcp-service.service ]; then
      pass "TCP and UDP on same port allowed"
    else
      fail "Should allow same port on different protocols"
    fi

    # Test 4: Contract data preservation
    echo "Test 4: Contract data preservation..."
    [ "${toString test4_dataPreservation.contractCount}" = "2" ] && \
    [ "${toString test4_dataPreservation.httpPort}" = "8080" ] && \
    [ "${test4_dataPreservation.httpHostname}" = "myapp.example.com" ] && \
    [ "${test4_dataPreservation.httpPath}" = "/api" ] && \
    [ "${test4_dataPreservation.httpTransport}" = "http2" ] && \
    [ "${toString test4_dataPreservation.httpAcme}" = "1" ] && \
    [ "${test4_dataPreservation.httpHealthPath}" = "/health" ] && \
    [ "${toString test4_dataPreservation.httpHealthInterval}" = "10" ] && \
    [ "${toString test4_dataPreservation.grpcPort}" = "9000" ] && \
    [ "${toString test4_dataPreservation.grpcInternal}" = "1" ] && \
    pass "All contract fields preserved" || \
    fail "Contract data not preserved correctly"

    # Test 5: Backward compatibility
    echo "Test 5: Backward compatibility..."
    if [ -f ${test5_backwardCompat.legacy-service}/legacy-service.service ]; then
      pass "Services without port declarations work"
    else
      fail "Should build without port declarations"
    fi

    # Test 6: ACME without hostname
    echo "Test 6: tls.acme without hostname..."
    if [ "${toString test6_acmeNoHostname.success}" = "1" ]; then
      fail "Should have caught ACME without hostname"
    else
      pass "ACME without hostname rejected"
    fi

    # Test 7: openFirewall + internal warning
    echo "Test 7: openFirewall + internal contradiction..."
    if [ -f ${test7_firewallInternalWarning.contradictory}/contradictory.service ]; then
      pass "Built with warning for contradictory options"
    else
      fail "Should build with warning"
    fi

    # Test 8: checkPortContracts catches collisions
    echo "Test 8: checkPortContracts collision detection..."
    if [ "${toString test8_checkUtilityCollision.success}" = "1" ]; then
      fail "checkPortContracts should have caught collision"
    else
      pass "checkPortContracts detected collision"
    fi

    # Test 9: checkPortContracts passes when no collisions
    echo "Test 9: checkPortContracts passes for valid config..."
    if [ "${toString test9_checkUtilityOk}" = "1" ]; then
      pass "checkPortContracts passed for valid config"
    else
      fail "checkPortContracts should have passed"
    fi

    # Test 10: Multiple ports on same service
    echo "Test 10: Multiple ports on same service..."
    if [ -f ${test10_multiPortSameService.multi-port}/multi-port.service ]; then
      pass "Multi-port service built"
    else
      fail "Should build with multiple ports"
    fi

    # Test 11: Disabled service ports don't collide
    echo "Test 11: Disabled service ports don't collide..."
    if [ -f ${test11_disabledServiceNoCollision.active}/active.service ]; then
      pass "Disabled service ports ignored in collision check"
    else
      fail "Should build — disabled service should not collide"
    fi

    echo
    echo "========================================="
    echo "Results: $passed passed, $failed failed"
    echo "========================================="
    [ "$failed" -eq 0 ] || exit 1
  '';

in
{
  inherit
    test1_validPortContracts
    test2_portCollision
    test3_differentProtocols
    test4_dataPreservation
    test5_backwardCompat
    test6_acmeNoHostname
    test7_firewallInternalWarning
    test8_checkUtilityCollision
    test9_checkUtilityOk
    test10_multiPortSameService
    test11_disabledServiceNoCollision
    verifyScript
    ;

  all = pkgs.runCommand "port-contract-test-all" { } ''
    mkdir -p $out
    ${verifyScript} 2>&1 | tee $out/test-results.txt
  '';
}
