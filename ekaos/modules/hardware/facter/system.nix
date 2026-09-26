# Adios port of ekaos/modules/hardware/facter/system.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ ... }:

{
  options = { };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  # Informational — the system field from the facter report
  # can be used for platform detection if needed.
  # The legacy config body is a no-op; impl returns an empty fragment.
  impl =
    { inputs, ... }:
    if (inputs.facter.enable && inputs.facter.report.system or null != null) then
      {
        # No action needed — system platform is already set by the build
        # This module exists for completeness and potential future use
      }
    else
      { };
}
