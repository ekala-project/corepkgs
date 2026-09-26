# Adios port of ekaos/modules/config/locale.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

let
  tzdir = "${pkgs.tzdata}/share/zoneinfo";
in

{
  options = {
    time = {
      options = {
        timeZone = {
          type = types.nullOr types.string;
          default = null;
          example = "America/New_York";
          description = ''
            IANA time zone for the system. null defaults to UTC.
            See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
          '';
        };

        hardwareClockInLocalTime = {
          type = types.bool;
          default = false;
          description = "If set, the hardware clock is kept in local time instead of UTC.";
        };
      };
      description = "System time and time zone settings.";
    };

    i18n = {
      options = {
        defaultLocale = {
          type = types.string;
          default = "C.UTF-8";
          example = "en_US.UTF-8";
          description = ''
            The default locale. Determines language for program messages,
            date/time format, sort order, etc.
          '';
        };

        extraLocaleSettings = {
          type = types.attrsOf types.string;
          default = { };
          example = {
            LC_TIME = "de_DE.UTF-8";
            LC_MONETARY = "de_DE.UTF-8";
          };
          description = ''
            Per-category locale overrides. Keys are LC_* variable names.
          '';
        };

        supportedLocales = {
          type = types.listOf types.string;
          default = [ "all" ];
          example = [
            "en_US.UTF-8/UTF-8"
            "de_DE.UTF-8/UTF-8"
          ];
          description = ''
            List of locales to generate. Use [ "all" ] to generate all locales.
          '';
        };

        glibcLocales = {
          type = types.nullOr types.derivation;
          default = null;
          description = ''
            Override the glibc locales package. When null, the default
            locales are built from supportedLocales.
          '';
        };
      };
      description = "Internationalisation (locale) settings.";
    };

    console = {
      options = {
        keyMap = {
          type = types.string;
          default = "us";
          example = "de";
          description = "Virtual console keyboard layout.";
        };

        font = {
          type = types.nullOr types.string;
          default = null;
          example = "Lat2-Terminus16";
          description = "Console font. null uses the kernel default.";
        };
      };
      description = "Virtual console keymap and font settings.";
    };
  };

  impl =
    { options, ... }:
    let
      optionalString = cond: s: if cond then s else "";
      escapeShellArg = s: "'${builtins.replaceStrings [ "'" ] [ "'\\''" ] (toString s)}'";
      lcVars = builtins.map (name: "${name}=${options.i18n.extraLocaleSettings.${name}}") (
        builtins.attrNames options.i18n.extraLocaleSettings
      );
    in
    {
      # Timezone: symlink /etc/localtime to the zoneinfo file
      environment.etc."localtime" =
        if options.time.timeZone != null then
          {
            source = "${tzdir}/${options.time.timeZone}";
          }
        else
          { };

      environment.etc."timezone" =
        if options.time.timeZone != null then
          {
            text = options.time.timeZone;
          }
        else
          { };

      # Locale: set LANG and LC_* in /etc/locale.conf
      environment.etc."locale.conf".text = ''
        LANG=${options.i18n.defaultLocale}
        ${builtins.concatStringsSep "\n" lcVars}
      '';

      # Console keymap and font
      system.activationScripts.console = {
        deps = [ "etc" ];
        text = ''
          # Load console keymap
          if [ -e /dev/tty1 ] && command -v loadkeys >/dev/null 2>&1; then
            loadkeys ${escapeShellArg options.console.keyMap} 2>/dev/null || true
          fi

          ${optionalString (options.console.font != null) ''
            # Set console font
            if command -v setfont >/dev/null 2>&1; then
              setfont ${escapeShellArg options.console.font} 2>/dev/null || true
            fi
          ''}
        '';
      };

      # Add tzdata to system packages
      environment.systemPackages = [ pkgs.tzdata ];
    };
}
