# Minimal test to debug service system
{
  pkgs ? import ../../. { },
}:

let
  services = import ../default.nix { inherit pkgs; };

  # Simplest possible service
  serviceConfig = {
    test-service = {
      enable = true;
      description = "Test Service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [
        "hello"
        "world"
      ];
    };
  };

  evaluated = services.evalServices serviceConfig;

in
{
  # Debug: show evaluated config
  inherit evaluated;

  # Try to build
  systemdService = services.buildSystemdUserServices serviceConfig;
}
