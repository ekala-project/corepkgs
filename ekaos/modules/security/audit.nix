# Adios port of ekaos/modules/security/audit.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.union [
        types.bool
        (types.enum "auditEnableLock" [ "lock" ])
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

    package = {
      type = types.derivation;
      default = pkgs.audit;
      description = "Audit userspace tools package.";
    };

    backlogLimit = {
      type = types.int;
      default = 1024;
      description = ''
        Size of the kernel audit buffer. If the buffer fills up before
        auditd reads events, the behavior depends on failureMode.
      '';
    };

    failureMode = {
      type = types.enum "auditFailureMode" [
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

    rateLimit = {
      type = types.int;
      default = 0;
      description = ''
        Maximum number of audit messages per second. 0 disables rate limiting.
      '';
    };

    rules = {
      type = types.listOf types.string;
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

  assertions = [
    {
      verify = { options }: options.backlogLimit > 0;
      explain = { options }: "backlogLimit must be positive, got ${toString options.backlogLimit}";
    }
    {
      verify = { options }: options.rateLimit >= 0;
      explain = { options }: "rateLimit must be non-negative, got ${toString options.rateLimit}";
    }
  ];

  impl =
    { options, ... }:
    let
      enabledValue =
        if options.enable == true then
          "1"
        else if options.enable == "lock" then
          "1"
        else
          "0";

      auditRulesFile = pkgs.writeText "audit.rules" (
        builtins.concatStringsSep "\n" (
          # Delete all existing rules first
          [ "-D" ]
          # Set buffer size
          ++ [ "-b ${toString options.backlogLimit}" ]
          # Set failure mode
          ++ [
            "-f ${
              toString (
                if options.failureMode == "silent" then
                  0
                else if options.failureMode == "printk" then
                  1
                else
                  2
              )
            }"
          ]
          # Set rate limit
          ++ (if (options.rateLimit > 0) then [ "-r ${toString options.rateLimit}" ] else [ ])
          # User-defined rules
          ++ options.rules
          # Lock rules if requested (must be last)
          ++ (if (options.enable == "lock") then [ "-e 2" ] else [ ])
        )
        + "\n"
      );
    in
    if (options.enable != false) then
      {
        # Enable audit at boot via kernel parameters
        boot.kernelParams = [
          "audit=${enabledValue}"
          "audit_backlog_limit=${toString options.backlogLimit}"
        ];

        # Install audit tools
        environment.systemPackages = [ options.package ];

        # Install audit rules file
        environment.etc."audit/audit.rules".source = auditRulesFile;

        # Load audit rules at activation
        # TODO(adios-cutover): legacy stringAfter [ "etc" ] ordering lost.
        system.activationScripts.audit = ''
          # Create audit directories
          mkdir -p /etc/audit
          mkdir -p /var/log/audit

          # Load audit rules if the kernel supports it
          if [ -d /proc/sys/kernel ]; then
            ${options.package}/bin/auditctl -R ${auditRulesFile} 2>/dev/null || true
          fi
        '';
      }
    else
      { };
}
