# Adios port of ekaos/modules/boot/containers.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    # Legacy path: boot.isContainer.
    isContainer = {
      type = types.bool;
      default = false;
      description = ''
        Whether this system is running as a lightweight container
        inside another system (e.g. systemd-nspawn, Docker, LXC).

        When true, some boot and hardware modules are skipped since
        the host manages the kernel and hardware.
      '';
    };

    # Legacy path: boot.containers.enable.
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable support for running managed containers
        (systemd-nspawn).
      '';
    };
  };

  inputs = {
    # TODO(adios-cutover): provides systemd.package (defined in
    # ekaos/modules/system/toplevel.nix); flat leaf name pending the
    # system/toplevel port — full legacy path used below.
    systemd.from = { root }: root.system.toplevel;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        (
          if options.isContainer then
            {
              boot = {
                # TODO(adios-cutover): priority lost (was mkForce).
                kernelModules = [ ];
                # TODO(adios-cutover): priority lost (was mkDefault).
                initrd.enable = false;
                # TODO(adios-cutover): priority lost (was mkDefault).
                loader.systemd-boot.enable = false;
              };
            }
          else
            { }
        )

        (
          if options.enable then
            {
              environment.systemPackages = [ inputs.systemd.systemd.package ];
            }
          else
            { }
        )
      ];
    };
}
