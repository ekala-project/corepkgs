# Kernel security hardening options
{
  config,
  lib,
  ...
}:

with lib;

{
  options.security = {
    protectKernelImage = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to prevent replacing the running kernel image.
        Disables hibernation and kexec_load.
      '';
    };

    lockKernelModules = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Disable kernel module loading once the system is fully initialised.
        Problems caused by delayed loading can be fixed by adding the
        module(s) to boot.kernelModules.
      '';
    };

    allowUserNamespaces = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow creation of user namespaces. Disabling this
        limits the attack surface but breaks sandboxed Nix builds and
        unprivileged containers.
      '';
    };

    forcePageTableIsolation = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to force Page Table Isolation (PTI) even on CPUs that
        claim to be safe from Meltdown.
      '';
    };

    unprivilegedUsernsClone = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow unprivileged user namespace cloning.

        Required by many sandboxing tools (Flatpak, Bubblewrap, etc.).
        Disabling limits the attack surface.
      '';
    };

    allowSimultaneousMultithreading = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to allow Simultaneous Multi-Threading (SMT/HyperThreading).

        Disabling SMT mitigates some CPU side-channel attacks but
        reduces performance.
      '';
    };

    polkit = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable PolicyKit for privilege management.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra PolicyKit configuration rules (JavaScript).";
      };

      adminIdentities = mkOption {
        type = types.listOf types.str;
        default = [ "unix-group:wheel" ];
        description = "Identities that are considered system administrators by PolicyKit.";
      };
    };

    rtkit = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable RealtimeKit for real-time scheduling
          for user processes (used by PulseAudio/PipeWire).
        '';
      };
    };

    pki = {
      certificateFiles = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Additional CA certificate files to trust system-wide.";
      };

      certificates = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional CA certificates (PEM format strings) to trust.";
      };

      caCertificateBlacklist = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "CA certificate common names to remove from the trust store.";
      };

      installCACerts = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to install the default CA certificate bundle.";
      };
    };

    tpm2 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable TPM 2.0 support.

          Sets up udev rules and the tss user/group for TPM access.
        '';
      };

      applyUdevRules = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to apply udev rules for TPM device access.";
      };

      tssUser = mkOption {
        type = types.str;
        default = "tss";
        description = "User for TPM access.";
      };

      tssGroup = mkOption {
        type = types.str;
        default = "tss";
        description = "Group for TPM access.";
      };

      tctiEnvironment = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to set TPM2 TCTI environment variables.";
        };
      };
    };

    doas = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable doas as a sudo alternative.
        '';
      };

      wheelNeedsPassword = mkOption {
        type = types.bool;
        default = true;
        description = "Whether wheel group members need a password for doas.";
      };

      extraRules = mkOption {
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

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra lines appended to /etc/doas.conf.";
      };
    };
  };

  config = mkMerge [
    (mkIf config.security.protectKernelImage {
      boot.kernelParams = [ "nohibernate" ];
      boot.kernel.sysctl."kernel.kexec_load_disabled" = mkDefault true;
    })

    (mkIf (!config.security.allowUserNamespaces) {
      boot.kernel.sysctl."user.max_user_namespaces" = 0;
    })

    (mkIf config.security.forcePageTableIsolation {
      boot.kernelParams = [ "pti=on" ];
    })

    (mkIf config.security.lockKernelModules {
      system.activationScripts.lockKernelModules = stringAfter [ "etc" ] ''
        # Disable kernel module loading (takes effect until reboot)
        if [ -w /proc/sys/kernel/modules_disabled ]; then
          echo 1 > /proc/sys/kernel/modules_disabled || true
        fi
      '';
    })

    (mkIf (!config.security.unprivilegedUsernsClone) {
      boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 0;
    })

    (mkIf (!config.security.allowSimultaneousMultithreading) {
      boot.kernelParams = [ "nosmt" ];
    })

    # TPM2
    (mkIf config.security.tpm2.enable {
      users.users.${config.security.tpm2.tssUser} = {
        isSystemUser = true;
        group = config.security.tpm2.tssGroup;
        description = "TPM2 Software Stack user";
      };
      users.groups.${config.security.tpm2.tssGroup} = { };
    })

    # PKI
    (mkIf (config.security.pki.certificates != [ ] || config.security.pki.certificateFiles != [ ]) {
      environment.etc."ssl/certs/ca-certificates.crt".text =
        concatStringsSep "\n" config.security.pki.certificates;
    })

    # doas
    (mkIf config.security.doas.enable {
      environment.systemPackages = [
        (pkgs.doas or (throw "doas package not available"))
      ];

      environment.etc."doas.conf".text =
        let
          wheelRule =
            if config.security.doas.wheelNeedsPassword then "permit :wheel" else "permit nopass :wheel";
        in
        ''
          # Generated by ekaos
          ${wheelRule}
          ${config.security.doas.extraConfig}
        '';
    })
  ];
}
