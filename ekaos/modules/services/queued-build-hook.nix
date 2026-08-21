# queued-build-hook — async post-build hook for Nix
# Queues post-build actions (e.g., uploading to a binary cache)
# and processes them asynchronously via a daemon.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.queued-build-hook;

  # Build the post-build script that enqueues jobs
  postBuildScript = pkgs.writeShellScript "queued-build-hook-enqueue" ''
    ${cfg.postBuildScriptContent}
  '';

in

{
  options = {
    services.queued-build-hook = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable queued-build-hook.

          When enabled, registers a Nix post-build-hook that enqueues
          build outputs for async processing (e.g., uploading to a
          binary cache).
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.queued-build-hook or (throw "queued-build-hook package not available in core-pkgs");
        defaultText = literalExpression "pkgs.queued-build-hook";
        description = "The queued-build-hook package to use.";
      };

      description = mkOption {
        type = types.str;
        default = "Queued Build Hook Daemon";
        description = "Service description.";
      };

      command = mkOption {
        type = types.str;
        internal = true;
        description = "Command to run (set automatically).";
      };

      args = mkOption {
        type = types.listOf types.str;
        internal = true;
        default = [ ];
        description = "Command arguments (set automatically).";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User to run service as.";
      };

      restartPolicy = mkOption {
        type = types.str;
        default = "always";
        description = "Restart policy.";
      };

      systemd = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Systemd-specific options.";
      };

      postBuildScriptContent = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set -eu
          set -f  # disable globbing
          export IFS=' '

          echo "Uploading paths: $OUT_PATHS"
          exec nix copy --to "s3://my-cache" $OUT_PATHS
        '';
        description = ''
          Content of the post-build script executed for each build output.

          Available environment variables:
          - OUT_PATHS: space-separated list of output paths
          - DRV_PATH: the derivation that was built
        '';
      };

      credentials = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          AWS_ACCESS_KEY_ID = "/run/secrets/aws-key-id";
          AWS_SECRET_ACCESS_KEY = "/run/secrets/aws-secret-key";
        };
        description = ''
          Credential files to load into the daemon's environment.

          Keys are environment variable names, values are paths to
          files whose contents become the variable values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # The daemon service
    services.queued-build-hook = {
      command = "${cfg.package}/bin/queued-build-hook";
      args = [ "daemon" ];
      user = "root";
      restartPolicy = "always";
      systemd = {
        after = [ "nix-daemon.service" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # Register as Nix post-build-hook
    nix.extraOptions = ''
      post-build-hook = ${postBuildScript}
    '';

    # Create queue directory
    system.activationScripts.queued-build-hook = stringAfter [ "etc" ] ''
      mkdir -p /var/lib/queued-build-hook
    '';
  };
}
