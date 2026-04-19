# Runit-specific service options
# See: http://smarden.org/runit/runsv.8.html

{ lib }:

with lib;

{
  runitOptions = { name, config, ... }: {
    options = {
      # Supervision directory
      superviseDirectory = mkOption {
        type = types.str;
        default = "/etc/sv/${name}";
        example = "/etc/sv/myservice";
        description = ''
          Directory where the runit service will be installed.

          Common locations:
          - /etc/sv/<service> - Service definition directory
          - /run/service/<service> - Active supervision (symlink to /etc/sv/<service>)

          The service directory contains the run script and optional
          finish, check, and log subdirectories.
        '';
      };

      # Finish script timeout
      timeoutFinish = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 300;
        description = ''
          Maximum seconds to wait for the finish script to complete.

          If the finish script doesn't complete within this time,
          runsv will send SIGKILL to terminate it.

          If not specified, runsv uses its default behavior.
        '';
      };

      # Logging configuration
      logScript = mkOption {
        type = types.nullOr types.lines;
        default = null;
        example = literalExpression ''
          '''
          #!/bin/sh
          exec svlogd -tt /var/log/myservice
          '''
        '';
        description = ''
          Optional logging run script for the service.

          If specified, creates a log/ subdirectory with this run script.
          The service's stdout/stderr will be piped to this logger.

          Typically uses svlogd for log rotation and management.
        '';
      };

      # Extra content for run script
      extraRunScript = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          '''
          # Set custom resource limits
          ulimit -n 4096
          ulimit -u 256
          '''
        '';
        description = ''
          Additional shell script content to include in the run script,
          inserted after environment setup but before the exec command.

          Useful for:
          - Setting resource limits (ulimit)
          - Additional environment setup
          - Conditional logic before starting
        '';
      };

      # Extra content for finish script
      extraFinishScript = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          '''
          # Clean up temporary files
          rm -rf /tmp/myservice-*
          '''
        '';
        description = ''
          Additional shell script content to include in the finish script,
          inserted after the postStop hook (if any).

          The finish script receives the exit code and signal number
          as arguments ($1 and $2).
        '';
      };

      # Raw passthrough for advanced configurations
      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        example = literalExpression ''
          {
            checkScript = '''
              #!/bin/sh
              # Health check logic
              curl -f http://localhost:8080/health
            ''';
          }
        '';
        description = ''
          Additional configuration options not covered by typed options above.

          Supported keys:
          - checkScript: Health check script content

          Use this for advanced runit features or custom extensions.
        '';
      };
    };
  };
}
