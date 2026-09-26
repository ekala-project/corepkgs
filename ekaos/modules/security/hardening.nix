# Adios port of ekaos/modules/security/hardening.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# NOTE: the legacy header is `{ config, lib, ... }:` but its doas branch
# references `pkgs.doas`; `pkgs` is added to the header here (required for
# the reference to resolve).
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    protectKernelImage = {
      type = types.bool;
      default = false;
      description = ''
        Whether to prevent replacing the running kernel image.
        Disables hibernation and kexec_load.
      '';
    };

    lockKernelModules = {
      type = types.bool;
      default = false;
      description = ''
        Disable kernel module loading once the system is fully initialised.
        Problems caused by delayed loading can be fixed by adding the
        module(s) to boot.kernelModules.
      '';
    };

    allowUserNamespaces = {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow creation of user namespaces. Disabling this
        limits the attack surface but breaks sandboxed Nix builds and
        unprivileged containers.
      '';
    };

    forcePageTableIsolation = {
      type = types.bool;
      default = false;
      description = ''
        Whether to force Page Table Isolation (PTI) even on CPUs that
        claim to be safe from Meltdown.
      '';
    };

    unprivilegedUsernsClone = {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow unprivileged user namespace cloning.

        Required by many sandboxing tools (Flatpak, Bubblewrap, etc.).
        Disabling limits the attack surface.
      '';
    };

    allowSimultaneousMultithreading = {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow Simultaneous Multi-Threading (SMT/HyperThreading).

        Disabling SMT mitigates some CPU side-channel attacks but
        reduces performance.
      '';
    };

    polkitEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable PolicyKit for privilege management.
      '';
    };

    polkitExtraConfig = {
      type = types.string;
      default = "";
      description = "Extra PolicyKit configuration rules (JavaScript).";
    };

    polkitAdminIdentities = {
      type = types.listOf types.string;
      default = [ "unix-group:wheel" ];
      description = "Identities that are considered system administrators by PolicyKit.";
    };

    rtkitEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable RealtimeKit for real-time scheduling
        for user processes (used by PulseAudio/PipeWire).
      '';
    };

    pkiCertificateFiles = {
      type = types.listOf types.pathLike;
      default = [ ];
      description = "Additional CA certificate files to trust system-wide.";
    };

    pkiCertificates = {
      type = types.listOf types.string;
      default = [ ];
      description = "Additional CA certificates (PEM format strings) to trust.";
    };

    pkiCaCertificateBlacklist = {
      type = types.listOf types.string;
      default = [ ];
      description = "CA certificate common names to remove from the trust store.";
    };

    pkiInstallCACerts = {
      type = types.bool;
      default = true;
      description = "Whether to install the default CA certificate bundle.";
    };

    tpm2Enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable TPM 2.0 support.

        Sets up udev rules and the tss user/group for TPM access.
      '';
    };

    tpm2ApplyUdevRules = {
      type = types.bool;
      default = true;
      description = "Whether to apply udev rules for TPM device access.";
    };

    tpm2TssUser = {
      type = types.string;
      default = "tss";
      description = "User for TPM access.";
    };

    tpm2TssGroup = {
      type = types.string;
      default = "tss";
      description = "Group for TPM access.";
    };

    tpm2TctiEnvironmentEnable = {
      type = types.bool;
      default = false;
      description = "Whether to set TPM2 TCTI environment variables.";
    };

    doasEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable doas as a sudo alternative.
      '';
    };

    doasWheelNeedsPassword = {
      type = types.bool;
      default = true;
      description = "Whether wheel group members need a password for doas.";
    };

    doasExtraRules = {
      type = types.listOf types.attrs;
      default = [ ];
      example = [
        {
          users = [ "alice" ];
          noPass = true;
        }
      ];
      description = "Extra doas rules.";
    };

    doasExtraConfig = {
      type = types.string;
      default = "";
      description = "Extra lines appended to /etc/doas.conf.";
    };
  };

  impl =
    { options, ... }:
    lib.merge.attrs.recursively {
      mutators = [
        (
          if options.protectKernelImage then
            {
              boot.kernelParams = [ "nohibernate" ];
              # TODO(adios-cutover): legacy mkDefault priority lost.
              boot.kernel.sysctl."kernel.kexec_load_disabled" = true;
            }
          else
            { }
        )

        (
          if (!options.allowUserNamespaces) then
            {
              boot.kernel.sysctl."user.max_user_namespaces" = 0;
            }
          else
            { }
        )

        (
          if options.forcePageTableIsolation then
            {
              boot.kernelParams = [ "pti=on" ];
            }
          else
            { }
        )

        # TODO(adios-cutover): legacy stringAfter [ "etc" ] ordering lost.
        (
          if options.lockKernelModules then
            {
              system.activationScripts.lockKernelModules = ''
                # Disable kernel module loading (takes effect until reboot)
                if [ -w /proc/sys/kernel/modules_disabled ]; then
                  echo 1 > /proc/sys/kernel/modules_disabled || true
                fi
              '';
            }
          else
            { }
        )

        (
          if (!options.unprivilegedUsernsClone) then
            {
              boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 0;
            }
          else
            { }
        )

        (
          if (!options.allowSimultaneousMultithreading) then
            {
              boot.kernelParams = [ "nosmt" ];
            }
          else
            { }
        )

        # TPM2
        (
          if options.tpm2Enable then
            {
              users.users.${options.tpm2TssUser} = {
                isSystemUser = true;
                group = options.tpm2TssGroup;
                description = "TPM2 Software Stack user";
              };
              users.groups.${options.tpm2TssGroup} = { };
            }
          else
            { }
        )

        # PKI
        (
          if (options.pkiCertificates != [ ] || options.pkiCertificateFiles != [ ]) then
            {
              environment.etc."ssl/certs/ca-certificates.crt".text =
                builtins.concatStringsSep "\n" options.pkiCertificates;
            }
          else
            { }
        )

        # doas
        (
          if options.doasEnable then
            {
              environment.systemPackages = [
                (pkgs.doas or (throw "doas package not available"))
              ];

              environment.etc."doas.conf".text =
                let
                  wheelRule = if options.doasWheelNeedsPassword then "permit :wheel" else "permit nopass :wheel";
                in
                ''
                  # Generated by ekaos
                  ${wheelRule}
                  ${options.doasExtraConfig}
                '';
            }
          else
            { }
        )
      ];
    };
}
