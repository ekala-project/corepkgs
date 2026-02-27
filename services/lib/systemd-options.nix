# Systemd-specific service options
{ lib }:

let
  inherit (lib) types mkOption literalExpression;
in
{
  systemdOptions = {
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
      default = [ "default.target" ];
      description = ''
        Targets that should pull in this service.
        For user services, typically "default.target".
      '';
    };
  };
}
