# Adios port of ekaos/modules/hardware/facter/printing.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.printer or [ ]) > 0 && inputs.virt.noneEnable;
      description = "Whether to enable Facter printer detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  # TODO(adios-cutover): legacy impl body is only a TODO comment (no
  # services.printing/CUPS module ported yet); impl returns an empty fragment.
  # TODO(corepkgs): Port services.printing (CUPS) module, then enable:
  # services.printing.enable = lib.mkDefault true;
  impl = { ... }: { };
}
