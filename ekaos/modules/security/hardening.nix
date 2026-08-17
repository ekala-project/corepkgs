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
  ];
}
