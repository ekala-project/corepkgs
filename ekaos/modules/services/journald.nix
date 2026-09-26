# Adios port of ekaos/modules/services/journald.nix.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable systemd-journald log management.

        systemd-journald is a system service that collects and stores
        logging data. It creates and maintains structured, indexed journals.
      '';
    };

    settings = {
      options = {
        storage = {
          type = types.nullOr (
            types.enum "storage" [
              "volatile"
              "persistent"
              "auto"
              "none"
            ]
          );
          default = "persistent";
          description = ''
            Where to store journal data.

            - volatile: Store in /run/log/journal (RAM, lost on reboot)
            - persistent: Store in /var/log/journal (survives reboot)
            - auto: Persistent if /var/log/journal exists, volatile otherwise
            - none: Turn off all storage
          '';
        };

        compress = {
          type = types.nullOr types.bool;
          default = true;
          description = ''
            Whether to compress journal files.

            Reduces disk space usage at the cost of CPU time.
          '';
        };

        seal = {
          type = types.nullOr types.bool;
          default = true;
          description = ''
            Whether to enable Forward Secure Sealing (FSS).

            Provides cryptographic authentication of journal files.
          '';
        };

        systemMaxUse = {
          type = types.nullOr types.string;
          default = "1G";
          description = ''
            Maximum disk space the journal may use in /var/log/journal.

            Accepts K, M, G, T suffixes. Also accepts percentage (e.g., "15%").
          '';
        };

        systemKeepFree = {
          type = types.nullOr types.string;
          default = "10%";
          description = ''
            How much disk space to keep free in /var/log/journal.

            Journals will be deleted if less than this amount is free.
          '';
        };

        systemMaxFileSize = {
          type = types.nullOr types.string;
          default = "100M";
          description = ''
            Maximum size of individual journal files in /var/log/journal.

            When this size is reached, a new journal file is created.
          '';
        };

        systemMaxFiles = {
          type = types.nullOr types.int;
          default = 100;
          description = ''
            Maximum number of journal files to keep.

            Older files are deleted when this limit is reached.
          '';
        };

        runtimeMaxUse = {
          type = types.nullOr types.string;
          default = "100M";
          description = ''
            Maximum disk space the journal may use in /run/log/journal.

            This applies to volatile storage only.
          '';
        };

        runtimeKeepFree = {
          type = types.nullOr types.string;
          default = "10%";
          description = ''
            How much disk space to keep free in /run/log/journal.
          '';
        };

        runtimeMaxFileSize = {
          type = types.nullOr types.string;
          default = "50M";
          description = ''
            Maximum size of individual journal files in /run/log/journal.
          '';
        };

        runtimeMaxFiles = {
          type = types.nullOr types.int;
          default = 20;
          description = ''
            Maximum number of volatile journal files to keep.
          '';
        };

        maxRetentionSec = {
          type = types.nullOr types.string;
          default = null;
          description = ''
            Maximum time to store journal entries.

            Accepts systemd time span syntax (e.g. "1month", "3week", "2d").
            Older entries are deleted. If null, no time-based deletion.
          '';
        };

        maxFileSec = {
          type = types.nullOr types.string;
          default = "1day";
          description = ''
            Maximum time to store entries in a single file.

            Accepts systemd time span syntax (e.g. "1day", "1week").
            After this time, a new file is created.
          '';
        };

        forwardToSyslog = {
          type = types.nullOr types.bool;
          default = false;
          description = ''
            Whether to forward messages to traditional syslog daemon.

            Requires a syslog daemon to be running.
          '';
        };

        forwardToKMsg = {
          type = types.nullOr types.bool;
          default = false;
          description = ''
            Whether to forward messages to /dev/kmsg (kernel log).
          '';
        };

        forwardToConsole = {
          type = types.nullOr types.bool;
          default = false;
          description = ''
            Whether to forward messages to the system console.

            Useful for debugging but can be noisy.
          '';
        };

        rateLimit = {
          # TODO(adios-cutover): submodule validation lost; defaults are
          # intervalSec=30, burst=10000 (see impl fallbacks).
          type = types.nullOr types.attrs;
          default = null;
          description = ''
            Rate limiting configuration.

            Limits the number of messages accepted per time interval.
          '';
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = ''
            Additional configuration lines for journald.conf.

            See journald.conf(5) for available options.
          '';
        };
      };
      description = "journald-specific configuration.";
    };
  };

  inputs = {
    # TODO(adios-cutover): verify leaf path once the service-managers batch
    # lands (legacy asserts on config.systemd.package).
    systemd.from = { root }: root."service-managers".systemd;
  };

  assertions = [
    {
      verify = { options, inputs }: !options.enable || inputs.systemd.package != null;
      explain = { options, inputs }: "systemd-journald requires systemd to be enabled";
    }
    {
      verify = { options, inputs }: !options.enable || options.settings.forwardToSyslog != true;
      explain = { options, inputs }: "forwardToSyslog requires a syslog daemon (not yet available)";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        s = options.settings;
        rateLimit = s.rateLimit or null;
      in
      {
        environment.etc."systemd/journald.conf" = {
          source = pkgs.writeText "journald.conf" ''
            # Generated by ekaos journald module
            [Journal]
            ${if s.storage or null != null then "Storage=${s.storage}" else ""}
            ${if s.compress or null != null then "Compress=${if s.compress then "yes" else "no"}" else ""}
            ${if s.seal or null != null then "Seal=${if s.seal then "yes" else "no"}" else ""}
            ${if s.systemMaxUse or null != null then "SystemMaxUse=${s.systemMaxUse}" else ""}
            ${if s.systemKeepFree or null != null then "SystemKeepFree=${s.systemKeepFree}" else ""}
            ${if s.systemMaxFileSize or null != null then "SystemMaxFileSize=${s.systemMaxFileSize}" else ""}
            ${if s.systemMaxFiles or null != null then "SystemMaxFiles=${toString s.systemMaxFiles}" else ""}
            ${if s.runtimeMaxUse or null != null then "RuntimeMaxUse=${s.runtimeMaxUse}" else ""}
            ${if s.runtimeKeepFree or null != null then "RuntimeKeepFree=${s.runtimeKeepFree}" else ""}
            ${if s.runtimeMaxFileSize or null != null then "RuntimeMaxFileSize=${s.runtimeMaxFileSize}" else ""}
            ${if s.runtimeMaxFiles or null != null then "RuntimeMaxFiles=${toString s.runtimeMaxFiles}" else ""}
            ${if s.maxRetentionSec or null != null then "MaxRetentionSec=${s.maxRetentionSec}" else ""}
            ${if s.maxFileSec or null != null then "MaxFileSec=${s.maxFileSec}" else ""}
            ${
              if s.forwardToSyslog or null != null then
                "ForwardToSyslog=${if s.forwardToSyslog then "yes" else "no"}"
              else
                ""
            }
            ${
              if s.forwardToKMsg or null != null then
                "ForwardToKMsg=${if s.forwardToKMsg then "yes" else "no"}"
              else
                ""
            }
            ${
              if s.forwardToConsole or null != null then
                "ForwardToConsole=${if s.forwardToConsole then "yes" else "no"}"
              else
                ""
            }
            ${
              if rateLimit != null then
                "RateLimitIntervalSec=${toString (rateLimit.intervalSec or 30)}\nRateLimitBurst=${
                  toString (rateLimit.burst or 10000)
                }"
              else
                ""
            }
            ${s.extraConfig or ""}
          '';
          mode = "0644";
        };

        # TODO(adios-cutover): legacy ordering (after "etc") lost; plain script.
        system.activationScripts.journald = ''
          # Create journal directories based on storage setting
          ${
            if (s.storage or "persistent") == "persistent" || (s.storage or null) == "auto" then
              ''
                mkdir -p /var/log/journal
                chmod 755 /var/log/journal

                # Create machine ID subdirectory if machine-id exists
                if [ -f /etc/machine-id ]; then
                  MACHINE_ID=$(cat /etc/machine-id)
                  mkdir -p /var/log/journal/$MACHINE_ID
                  chmod 755 /var/log/journal/$MACHINE_ID
                fi
              ''
            else
              ""
          }

          ${
            if (s.storage or null) == "volatile" || (s.storage or null) == "auto" then
              ''
                mkdir -p /run/log/journal
                chmod 755 /run/log/journal
              ''
            else
              ""
          }
        '';
      };
}
