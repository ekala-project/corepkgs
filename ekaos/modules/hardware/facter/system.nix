# Set system platform from facter report
{ config, lib, ... }:
{
  # Informational — the system field from the facter report
  # can be used for platform detection if needed
  config =
    lib.mkIf (config.hardware.facter.enable && config.hardware.facter.report.system or null != null)
      {
        # No action needed — system platform is already set by the build
        # This module exists for completeness and potential future use
      };
}
