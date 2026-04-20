# Test metadata configuration

{ config, lib, ... }:

with lib;

{
  options = {
    name = mkOption {
      type = types.str;
      description = "Name of the test";
      example = "my-ekaos-test";
    };

    meta = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Meta attributes for the test derivation.

        Common attributes:
        - timeout: Maximum test duration in seconds
        - maintainers: List of maintainers
        - platforms: Supported platforms
      '';
      example = literalExpression ''
        {
          timeout = 900;
          maintainers = [ "your-name" ];
        }
      '';
    };

    passthru = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Attributes to pass through to the test derivation.

        Automatically includes:
        - nodes: Built node configurations
        - driver: Test driver package
      '';
    };

    globalTimeout = mkOption {
      type = types.int;
      default = 900;
      description = ''
        Global timeout for the entire test in seconds.

        Tests exceeding this timeout will be killed.
      '';
    };
  };

  config = {
    # Automatically add nodes and driver to passthru
    passthru = {
      inherit (config) nodes;
      driver = config.driver;
    };

    # Set default timeout in meta if not specified
    meta = {
      timeout = mkDefault config.globalTimeout;
    };
  };
}
