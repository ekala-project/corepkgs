# Linux audit framework
# Configures kernel-level audit rules via auditctl
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.security.audit;

  enabledValue =
    if cfg.enable == true then
      "1"
    else if cfg.enable == "lock" then
      "1"
    else
      "0";

  auditRulesFile = pkgs.writeText "audit.rules" (
    concatStringsSep "\n" (
      # Delete all existing rules first
      [ "-D" ]
      # Set buffer size
      ++ [ "-b ${toString cfg.backlogLimit}" ]
      # Set failure mode
      ++ [
        "-f ${
          toString (
            if cfg.failureMode == "silent" then
              0
            else if cfg.failureMode == "printk" then
              1
            else
              2
          )
        }"
      ]
      # Set rate limit
      ++ optional (cfg.rateLimit > 0) "-r ${toString cfg.rateLimit}"
      # User-defined rules
      ++ cfg.rules
      # Lock rules if requested (must be last)
      ++ optional (cfg.enable == "lock") "-e 2"
    )
    + "\n"
  );

in

{
  options.security.audit = {
    enable = mkOption {
      type = types.oneOf [
        types.bool
        (types.enum [ "lock" ])
      ];
      default = false;
      description = ''
        Whether to enable the Linux audit framework.

        - false: Audit is disabled
        - true: Audit is enabled
        - "lock": Audit is enabled and rules are locked (cannot be changed
          at runtime without a reboot)
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.audit;
      description = "Audit userspace tools package.";
    };

    backlogLimit = mkOption {
      type = types.ints.positive;
      default = 1024;
      description = ''
        Size of the kernel audit buffer. If the buffer fills up before
        auditd reads events, the behavior depends on failureMode.
      '';
    };

    failureMode = mkOption {
      type = types.enum [
        "silent"
        "printk"
        "panic"
      ];
      default = "printk";
      description = ''
        Behavior when the audit buffer is exhausted.

        - silent: Silently drop events
        - printk: Log a kernel warning
        - panic: Kernel panic (for high-security environments)
      '';
    };

    rateLimit = mkOption {
      type = types.ints.unsigned;
      default = 0;
      description = ''
        Maximum number of audit messages per second. 0 disables rate limiting.
      '';
    };

    rules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "-w /etc/shadow -p wa -k shadow-access"
        "-w /etc/passwd -p wa -k passwd-access"
        "-a always,exit -F arch=b64 -S execve -k program-exec"
      ];
      description = ''
        Audit rules in auditctl format.
        See auditctl(8) for the full rule syntax.
      '';
    };
  };

  config = mkIf (cfg.enable != false) {
    # Enable audit at boot via kernel parameters
    boot.kernelParams = [
      "audit=${enabledValue}"
      "audit_backlog_limit=${toString cfg.backlogLimit}"
    ];

    # Install audit tools
    environment.systemPackages = [ cfg.package ];

    # Install audit rules file
    environment.etc."audit/audit.rules".source = auditRulesFile;

    # Load audit rules at activation
    system.activationScripts.audit = stringAfter [ "etc" ] ''
      # Create audit directories
      mkdir -p /etc/audit
      mkdir -p /var/log/audit

      # Load audit rules if the kernel supports it
      if [ -d /proc/sys/kernel ]; then
        ${cfg.package}/bin/auditctl -R ${auditRulesFile} 2>/dev/null || true
      fi
    '';
  };
}
