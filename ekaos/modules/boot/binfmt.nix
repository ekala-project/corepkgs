# Adios port of ekaos/modules/boot/binfmt.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    registrations = {
      type = types.attrsOf types.attrs;
      # TODO(adios-cutover): submodule validation lost. Each entry is a raw
      # attrset supporting: recognitionType ("magic"/"extension",
      # default "magic"), offset (null or int, default null),
      # magicOrExtension (string, required), mask (null or string,
      # default null), interpreter (path, required), preserveArgvZero,
      # fixBinary, matchCredentials (bool, default false), openBinary
      # (bool, default = the entry's matchCredentials).
      default = { };
      description = ''
        Extra binary formats to register with the kernel via binfmt_misc.

        See https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html
      '';
    };

    emulatedSystems = {
      type = types.listOf types.string;
      default = [ ];
      example = [
        "aarch64-linux"
        "armv7l-linux"
      ];
      description = ''
        List of systems to emulate via QEMU user-mode emulation.

        Automatically registers binfmt entries for the specified
        architectures using qemu-user. Also configures Nix to
        support building for these platforms.
      '';
    };

    preferStaticEmulators = {
      type = types.bool;
      default = false;
      description = ''
        Whether to use statically-linked emulators when available.

        Static emulators can be preloaded by the kernel, removing
        the need to make them available inside chroots and sandboxes.
      '';
    };
  };

  impl =
    { options, ... }:
    let
      # Format a registration for binfmt_misc. `or` fallbacks reproduce the
      # legacy submodule defaults (validation itself is lost, see TODO above).
      mkRegistration =
        name: reg:
        let
          recognitionType = reg.recognitionType or "magic";
          type = if recognitionType == "magic" then "M" else "E";
          offset = if (reg.offset or null) != null then toString reg.offset else "";
          matchCredentials = reg.matchCredentials or false;
          flags =
            (if (reg.preserveArgvZero or false) then "P" else "")
            + (if (reg.openBinary or matchCredentials) then "O" else "")
            + (if matchCredentials then "C" else "")
            + (if (reg.fixBinary or false) then "F" else "");
        in
        ":${name}:${type}:${offset}:${reg.magicOrExtension}:${reg.mask or ""}:${reg.interpreter}:${flags}";
    in
    lib.merge.attrs.recursively {
      mutators = [
        (
          if options.registrations != { } then
            {
              environment.etc."binfmt.d/ekaos.conf".text = builtins.concatStringsSep "\n" (
                builtins.map (n: mkRegistration n options.registrations.${n}) (
                  builtins.attrNames options.registrations
                )
              );

              # TODO(adios-cutover): stringAfter [ "etc" ] ordering dropped.
              system.activationScripts.binfmt = ''
                # Mount binfmt_misc if not already mounted
                if [ ! -d /proc/sys/fs/binfmt_misc ]; then
                  mkdir -p /proc/sys/fs/binfmt_misc
                fi
                if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
                  mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
                fi

                # Register formats
                if [ -f /etc/binfmt.d/ekaos.conf ]; then
                  while IFS= read -r line; do
                    [ -n "$line" ] && echo "$line" > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true
                  done < /etc/binfmt.d/ekaos.conf
                fi
              '';
            }
          else
            { }
        )

        (
          if options.emulatedSystems != [ ] then
            {
              nix.settings.extra-platforms = options.emulatedSystems;
            }
          else
            { }
        )
      ];
    };
  # Note: legacy config never consumes preferStaticEmulators; it is accepted
  # and exposed for other modules but has no effect here (same as legacy).
}
