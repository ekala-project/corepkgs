# Binary format (binfmt_misc) support
# Allows running foreign-architecture binaries via QEMU or other interpreters
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.binfmt;

  # Registration submodule
  registrationOpts =
    { name, config, ... }:
    {
      options = {
        recognitionType = mkOption {
          type = types.enum [
            "magic"
            "extension"
          ];
          default = "magic";
          description = "Whether to recognize executables by magic number or extension.";
        };

        offset = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Byte offset of the magic number used for recognition.";
        };

        magicOrExtension = mkOption {
          type = types.str;
          description = "The magic number or file extension to match on.";
        };

        mask = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Mask to AND with the byte sequence before matching.";
        };

        interpreter = mkOption {
          type = types.path;
          description = "The interpreter to invoke to run the program.";
        };

        preserveArgvZero = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to pass the original argv[0] to the interpreter.";
        };

        fixBinary = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to open the interpreter at registration time rather
            than when a binary is invoked. Useful for chroot/container
            scenarios.
          '';
        };

        matchCredentials = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to launch with the credentials of the binary
            rather than the interpreter (e.g. setuid bits).
          '';
        };

        openBinary = mkOption {
          type = types.bool;
          default = config.matchCredentials;
          defaultText = literalExpression "config.matchCredentials";
          description = ''
            Whether to pass the binary as an open file descriptor
            instead of a path.
          '';
        };
      };
    };

  # Format a registration for binfmt_misc
  mkRegistration =
    name: reg:
    let
      type = if reg.recognitionType == "magic" then "M" else "E";
      offset = optionalString (reg.offset != null) (toString reg.offset);
      flags =
        optionalString reg.preserveArgvZero "P"
        + optionalString reg.openBinary "O"
        + optionalString reg.matchCredentials "C"
        + optionalString reg.fixBinary "F";
    in
    ":${name}:${type}:${offset}:${reg.magicOrExtension}:${reg.mask or ""}:${reg.interpreter}:${flags}";

in

{
  options = {
    boot.binfmt = {
      registrations = mkOption {
        type = types.attrsOf (types.submodule registrationOpts);
        default = { };
        description = ''
          Extra binary formats to register with the kernel via binfmt_misc.

          See https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html
        '';
      };

      emulatedSystems = mkOption {
        type = types.listOf types.str;
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

      preferStaticEmulators = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use statically-linked emulators when available.

          Static emulators can be preloaded by the kernel, removing
          the need to make them available inside chroots and sandboxes.
        '';
      };
    };
  };

  config = mkMerge [
    # Register explicit binfmt entries
    (mkIf (cfg.registrations != { }) {
      environment.etc."binfmt.d/ekaos.conf".text = concatStringsSep "\n" (
        mapAttrsToList mkRegistration cfg.registrations
      );

      system.activationScripts.binfmt = stringAfter [ "etc" ] ''
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
    })

    # Set up QEMU user-mode emulation for emulated systems
    (mkIf (cfg.emulatedSystems != [ ]) {
      nix.settings.extra-platforms = cfg.emulatedSystems;
    })
  ];
}
