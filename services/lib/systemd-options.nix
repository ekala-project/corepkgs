# Systemd-specific service options
{ lib }:

let
  inherit (lib) types mkOption literalExpression;

  # Parameterized options function that accepts serviceType
  # serviceType: "user" or "system" to control defaults
  mkSystemdOptions = { serviceType ? "user" }:
    let
      defaultWantedBy = if serviceType == "user" then [ "default.target" ] else [ "multi-user.target" ];
      defaultWantedByDescription = if serviceType == "user"
        then "For user services, typically \"default.target\"."
        else "For system services, typically \"multi-user.target\".";
    in
    {
    # Allow raw systemd options to be passed through
    serviceConfig = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/lib/myservice" ];
        }
      '';
      description = ''
        Additional systemd Service section options.
        These are passed through directly to the [Service] section.
      '';
    };

    unitConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Additional systemd Unit section options.
      '';
    };

    wants = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Weak dependencies (Wants=).
      '';
    };

    requires = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Strong dependencies (Requires=).
      '';
    };

    after = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Start after these units (After=).
      '';
    };

    before = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Start before these units (Before=).
      '';
    };

    wantedBy = mkOption {
      type = types.listOf types.str;
      default = defaultWantedBy;
      description = ''
        Targets that should pull in this service.
        ${defaultWantedByDescription}
      '';
    };
  };
in
{
  # Expose the parameterized function
  inherit mkSystemdOptions;

  # Backward compatibility: export user service options as default
  systemdOptions = mkSystemdOptions { serviceType = "user"; };
}
