# Cross-platform service infrastructure
# Individual service modules define their own options extending the base service interface
# This module just provides documentation and ensures the services library is available
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Individual service modules define options at services.*
  # Each service module should provide:
  #   - enable: Whether to enable the service
  #   - description: Service description (optional)
  #   - command: Command to run
  #   - args: Command arguments (optional)
  #   - user: User to run as (optional)
  #   - group: Group to run as (optional)
  #   - restartPolicy: Restart policy (optional)
  #   - systemd: Systemd-specific options (optional)
  #   - settings: Application-specific configuration (optional)
  #
  # The systemd.nix module consumes services.* and generates systemd units

  options = {
    # No options defined here - individual service modules define their own
  };

  config = {
    # No configuration needed
  };
}
