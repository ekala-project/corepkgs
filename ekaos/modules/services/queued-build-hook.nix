# Adios port of ekaos/modules/services/queued-build-hook.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable queued-build-hook.

        When enabled, registers a Nix post-build-hook that enqueues
        build outputs for async processing (e.g., uploading to a
        binary cache).
      '';
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.queued-build-hook or null;
      description = "The queued-build-hook package to use.";
    };

    description = {
      type = types.string;
      default = "Queued Build Hook Daemon";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "root";
      description = "User to run service as.";
    };

    restartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy.";
    };

    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };

    postBuildScriptContent = {
      type = types.string;
      default = "";
      description = ''
        Content of the post-build script executed for each build output.

        Available environment variables:
        - OUT_PATHS: space-separated list of output paths
        - DRV_PATH: the derivation that was built
      '';
    };

    credentials = {
      type = types.attrsOf types.string;
      default = { };
      description = ''
        Credential files to load into the daemon's environment.

        Keys are environment variable names, values are paths to
        files whose contents become the variable values.
      '';
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain =
        { options, ... }: "package option must be set when enabled (queued-build-hook is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        postBuildScript = pkgs.writeShellScript "queued-build-hook-enqueue" ''
          ${options.postBuildScriptContent}
        '';
      in
      {
        services.queued-build-hook = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/queued-build-hook";
          args = [ "daemon" ];
          systemd = {
            after = [ "nix-daemon.service" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        nix.extraOptions = ''
          post-build-hook = ${postBuildScript}
        '';

        # TODO(adios-cutover): legacy ordering (after "etc") lost; plain script.
        system.activationScripts.queued-build-hook = ''
          mkdir -p /var/lib/queued-build-hook
        '';
      };
}
