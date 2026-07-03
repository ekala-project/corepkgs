# Timezone, locale, and console configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  tzdir = "${pkgs.tzdata}/share/zoneinfo";
  cfg = config.time;
  i18nCfg = config.i18n;
  consoleCfg = config.console;
in

{
  options = {
    time = {
      timeZone = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "America/New_York";
        description = ''
          IANA time zone for the system. null defaults to UTC.
          See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
        '';
      };

      hardwareClockInLocalTime = mkOption {
        type = types.bool;
        default = false;
        description = "If set, the hardware clock is kept in local time instead of UTC.";
      };
    };

    i18n = {
      defaultLocale = mkOption {
        type = types.str;
        default = "C.UTF-8";
        example = "en_US.UTF-8";
        description = ''
          The default locale. Determines language for program messages,
          date/time format, sort order, etc.
        '';
      };

      extraLocaleSettings = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          LC_TIME = "de_DE.UTF-8";
          LC_MONETARY = "de_DE.UTF-8";
        };
        description = ''
          Per-category locale overrides. Keys are LC_* variable names.
        '';
      };
    };

    console = {
      keyMap = mkOption {
        type = types.str;
        default = "us";
        example = "de";
        description = "Virtual console keyboard layout.";
      };

      font = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Lat2-Terminus16";
        description = "Console font. null uses the kernel default.";
      };
    };
  };

  config = {
    # Timezone: symlink /etc/localtime to the zoneinfo file
    environment.etc."localtime" = mkIf (cfg.timeZone != null) {
      source = "${tzdir}/${cfg.timeZone}";
    };

    environment.etc."timezone" = mkIf (cfg.timeZone != null) {
      text = cfg.timeZone;
    };

    # Locale: set LANG and LC_* in /etc/locale.conf
    environment.etc."locale.conf".text =
      let
        lcVars = mapAttrsToList (name: value: "${name}=${value}") i18nCfg.extraLocaleSettings;
      in
      ''
        LANG=${i18nCfg.defaultLocale}
        ${concatStringsSep "\n" lcVars}
      '';

    # Console keymap and font
    system.activationScripts.console = stringAfter [ "etc" ] ''
      # Load console keymap
      if [ -e /dev/tty1 ] && command -v loadkeys >/dev/null 2>&1; then
        loadkeys ${escapeShellArg consoleCfg.keyMap} 2>/dev/null || true
      fi

      ${optionalString (consoleCfg.font != null) ''
        # Set console font
        if command -v setfont >/dev/null 2>&1; then
          setfont ${escapeShellArg consoleCfg.font} 2>/dev/null || true
        fi
      ''}
    '';

    # Add tzdata to system packages
    environment.systemPackages = [ pkgs.tzdata ];
  };
}
