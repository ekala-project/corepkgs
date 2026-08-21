# Font configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.fonts;
in

{
  options = {
    fonts = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "[ pkgs.noto-fonts pkgs.liberation_ttf ]";
        description = ''
          Font packages to install system-wide.
        '';
      };

      enableDefaultPackages = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to include a basic set of default fonts
          (DejaVu, etc.) for reasonable out-of-the-box experience.
        '';
      };

      fontDir.enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to create a shared font directory at
          /run/current-system/sw/share/X11/fonts.
        '';
      };

      fontDir.decompressFonts = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to decompress fonts in the font directory.";
      };

      fontconfig = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable fontconfig for font discovery.";
        };

        antialias = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable font antialiasing.";
        };

        dpi = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = 96;
          description = "Force DPI for font rendering. null uses auto-detection.";
        };

        hinting = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enable font hinting.";
          };

          style = mkOption {
            type = types.enum [
              "none"
              "slight"
              "medium"
              "full"
            ];
            default = "slight";
            description = "Font hinting style.";
          };
        };

        subpixel = {
          rgba = mkOption {
            type = types.enum [
              "none"
              "rgb"
              "bgr"
              "vrgb"
              "vbgr"
            ];
            default = "none";
            description = "Subpixel rendering order. Depends on display type.";
          };

          lcdfilter = mkOption {
            type = types.enum [
              "none"
              "default"
              "light"
              "legacy"
            ];
            default = "default";
            description = "LCD filter for subpixel rendering.";
          };
        };

        defaultFonts = {
          serif = mkOption {
            type = types.listOf types.str;
            default = [ "DejaVu Serif" ];
            description = "Default serif font families.";
          };

          sansSerif = mkOption {
            type = types.listOf types.str;
            default = [ "DejaVu Sans" ];
            description = "Default sans-serif font families.";
          };

          monospace = mkOption {
            type = types.listOf types.str;
            default = [ "DejaVu Sans Mono" ];
            description = "Default monospace font families.";
          };

          emoji = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Default emoji font families.";
          };
        };

        localConf = mkOption {
          type = types.lines;
          default = "";
          description = "Extra fontconfig XML configuration.";
        };

        includeUserConf = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to include per-user fontconfig configuration.";
        };

        cache32Bit = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to generate 32-bit fontconfig caches (for 32-bit apps).";
        };

        allowBitmaps = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to allow bitmap fonts.";
        };

        useEmbeddedBitmaps = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to use embedded bitmaps in outline fonts.";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enableDefaultPackages && pkgs ? dejavu_fonts) {
      fonts.packages = [ pkgs.dejavu_fonts ];
    })

    (mkIf cfg.fontconfig.enable {
      environment.etc."fonts/fonts.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Font directories -->
          ${concatMapStringsSep "\n" (p: "<dir>${p}/share/fonts</dir>") cfg.packages}
          ${concatMapStringsSep "\n" (p: "<dir>${p}/lib/X11/fonts</dir>") cfg.packages}

          <!-- Antialiasing -->
          <match target="font">
            <edit name="antialias" mode="assign">
              <bool>${boolToString cfg.fontconfig.antialias}</bool>
            </edit>
          </match>

          <!-- Hinting -->
          <match target="font">
            <edit name="hinting" mode="assign">
              <bool>${boolToString cfg.fontconfig.hinting.enable}</bool>
            </edit>
            <edit name="hintstyle" mode="assign">
              <const>hint${cfg.fontconfig.hinting.style}</const>
            </edit>
          </match>

          <!-- Subpixel -->
          ${optionalString (cfg.fontconfig.subpixel.rgba != "none") ''
            <match target="font">
              <edit name="rgba" mode="assign">
                <const>${cfg.fontconfig.subpixel.rgba}</const>
              </edit>
              <edit name="lcdfilter" mode="assign">
                <const>lcd${cfg.fontconfig.subpixel.lcdfilter}</const>
              </edit>
            </match>
          ''}

          ${optionalString (cfg.fontconfig.dpi != null) ''
            <match target="pattern">
              <edit name="dpi" mode="assign">
                <double>${toString cfg.fontconfig.dpi}</double>
              </edit>
            </match>
          ''}

          <!-- Bitmap fonts -->
          ${optionalString (!cfg.fontconfig.allowBitmaps) ''
            <selectfont>
              <rejectfont>
                <pattern><patelt name="scalable"><bool>false</bool></patelt></pattern>
              </rejectfont>
            </selectfont>
          ''}

          <!-- Default font families -->
          ${concatMapStringsSep "\n" (family: ''
            <alias>
              <family>serif</family>
              <prefer><family>${family}</family></prefer>
            </alias>
          '') cfg.fontconfig.defaultFonts.serif}

          ${concatMapStringsSep "\n" (family: ''
            <alias>
              <family>sans-serif</family>
              <prefer><family>${family}</family></prefer>
            </alias>
          '') cfg.fontconfig.defaultFonts.sansSerif}

          ${concatMapStringsSep "\n" (family: ''
            <alias>
              <family>monospace</family>
              <prefer><family>${family}</family></prefer>
            </alias>
          '') cfg.fontconfig.defaultFonts.monospace}

          <!-- User config -->
          ${optionalString cfg.fontconfig.includeUserConf ''
            <include ignore_missing="yes" prefix="xdg">fontconfig/fonts.conf</include>
          ''}

          ${cfg.fontconfig.localConf}
        </fontconfig>
      '';
    })
  ];
}
