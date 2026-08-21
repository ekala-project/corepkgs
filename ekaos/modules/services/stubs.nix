# Service stubs for services that are referenced by other modules
# but not yet fully implemented in core-pkgs.
#
# These provide option declarations with enable = false defaults so that
# configs referencing these options can evaluate without errors.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    # Hydra CI server stub
    services.hydra = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Hydra CI. (Stub — not yet implemented in core-pkgs.)";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Port for the Hydra web interface.";
      };

      hydraURL = mkOption {
        type = types.str;
        default = "http://localhost:3000";
        description = "The base URL of the Hydra instance.";
      };

      notificationSender = mkOption {
        type = types.str;
        default = "hydra@localhost";
        description = "Email address used for Hydra notifications.";
      };

      buildMachinesFiles = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Paths to build machine files for Hydra.";
      };

      useSubstitutes = mkOption {
        type = types.bool;
        default = true;
        description = "Whether Hydra builds should use binary substitutes.";
      };

      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "The Hydra package to use.";
      };
    };

    # Grafana stub
    services.grafana = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Grafana. (Stub — not yet implemented in core-pkgs.)";
      };

      settings = mkOption {
        type = types.attrsOf (types.attrsOf types.anything);
        default = { };
        example = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
          };
        };
        description = ''
          Grafana settings (INI sections as nested attrs).
        '';
      };
    };

    # nix-serve stub
    services.nix-serve = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable nix-serve. (Stub — not yet implemented in core-pkgs.)";
      };

      secretKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the secret signing key for nix-serve.";
      };

      port = mkOption {
        type = types.port;
        default = 5000;
        description = "Port for nix-serve to listen on.";
      };
    };
  };

  # No config — these are stubs only
}
