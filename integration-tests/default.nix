# Integration Tests
#
# Unified entry point for all integration test frameworks in core-pkgs.
# This consolidates various test suites into a single, discoverable namespace.
#
# Usage:
#   nix-build -A integrationTests.runit.simple-http
#   nix-build -A integrationTests.ekaos.boot-process
#   nix-build -A integrationTests.runit.all
#
# Future test frameworks can be added here as they are developed.

{
  pkgs ? import ../. { },
}:

rec {
  # Runit service tests
  #
  # Module-based integration tests for runit services running in nix-build sandbox.
  # Tests use the unified services module system with Python test driver.
  #
  # Available tests:
  #   - simple-http: Basic HTTP server smoke test
  #   - multi-service: Backend-frontend interaction test
  #   - with-prestart: Service with preStart hook
  #   - with-environment: Environment variable passing
  #   - all: Meta-test running all runit tests
  runit = import ../services/tests/default.nix { inherit pkgs; };

  # ekaOS system tests
  #
  # VM-based integration tests for complete ekaOS systems.
  # Tests boot full systems in QEMU and verify system behavior.
  #
  # Available tests (when ekaosTest framework is available):
  #   - boot-process: Verify system boots to multi-user.target
  #   - simple: Basic system functionality test
  #   - service-management: Test systemd service lifecycle
  ekaos = pkgs.ekaosTests or { };

  # Placeholder for future test frameworks:
  #
  # systemd = ...;      # Systemd-specific integration tests
  # launchd = ...;      # Launchd (macOS) integration tests
  # networking = ...;   # Network configuration tests
  # containers = ...;   # Container/VM tests
}
