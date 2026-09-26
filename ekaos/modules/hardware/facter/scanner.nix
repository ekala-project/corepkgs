# Adios port of ekaos/modules/hardware/facter/scanner.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.scanner or [ ]) > 0 && inputs.virt.noneEnable;
      description = "Whether to enable Facter scanner detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  # TODO(adios-cutover): legacy impl body is only a TODO comment (no
  # hardware.sane module ported yet); impl returns an empty fragment.
  # TODO(corepkgs): Port hardware.sane module (sane-backends), then enable:
  # hardware.sane.enable = lib.mkDefault true;
  impl = { ... }: { };
}
