# Adios port of ekaos/modules/config/fonts.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    packages = {
      type = types.listOf types.derivation;
      default = [ ];
      description = ''
        Font packages to install system-wide.
      '';
    };

    enableDefaultPackages = {
      type = types.bool;
      default = true;
      description = ''
        Whether to include a basic set of default fonts
        (DejaVu, etc.) for reasonable out-of-the-box experience.
      '';
    };

    fontDir = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = ''
            Whether to create a shared font directory at
            /run/current-system/sw/share/X11/fonts.
          '';
        };

        decompressFonts = {
          type = types.bool;
          default = false;
          description = "Whether to decompress fonts in the font directory.";
        };
      };
      description = "Shared font directory settings.";
    };

    fontconfig = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = "Whether to enable fontconfig for font discovery.";
        };

        antialias = {
          type = types.bool;
          default = true;
          description = "Whether to enable font antialiasing.";
        };

        dpi = {
          type = types.nullOr types.int;
          default = null;
          example = 96;
          description = "Force DPI for font rendering. null uses auto-detection.";
        };

        hinting = {
          options = {
            enable = {
              type = types.bool;
              default = true;
              description = "Whether to enable font hinting.";
            };

            style = {
              type = types.enum "hinting-style" [
                "none"
                "slight"
                "medium"
                "full"
              ];
              default = "slight";
              description = "Font hinting style.";
            };
          };
          description = "Font hinting settings.";
        };

        subpixel = {
          options = {
            rgba = {
              type = types.enum "subpixel-rgba" [
                "none"
                "rgb"
                "bgr"
                "vrgb"
                "vbgr"
              ];
              default = "none";
              description = "Subpixel rendering order. Depends on display type.";
            };

            lcdfilter = {
              type = types.enum "subpixel-lcdfilter" [
                "none"
                "default"
                "light"
                "legacy"
              ];
              default = "default";
              description = "LCD filter for subpixel rendering.";
            };
          };
          description = "Subpixel rendering settings.";
        };

        defaultFonts = {
          options = {
            serif = {
              type = types.listOf types.string;
              default = [ "DejaVu Serif" ];
              description = "Default serif font families.";
            };

            sansSerif = {
              type = types.listOf types.string;
              default = [ "DejaVu Sans" ];
              description = "Default sans-serif font families.";
            };

            monospace = {
              type = types.listOf types.string;
              default = [ "DejaVu Sans Mono" ];
              description = "Default monospace font families.";
            };

            emoji = {
              type = types.listOf types.string;
              default = [ ];
              description = "Default emoji font families.";
            };
          };
          description = "Default font families.";
        };

        localConf = {
          type = types.string;
          default = "";
          description = "Extra fontconfig XML configuration.";
        };

        includeUserConf = {
          type = types.bool;
          default = true;
          description = "Whether to include per-user fontconfig configuration.";
        };

        cache32Bit = {
          type = types.bool;
          default = false;
          description = "Whether to generate 32-bit fontconfig caches (for 32-bit apps).";
        };

        allowBitmaps = {
          type = types.bool;
          default = true;
          description = "Whether to allow bitmap fonts.";
        };

        useEmbeddedBitmaps = {
          type = types.bool;
          default = false;
          description = "Whether to use embedded bitmaps in outline fonts.";
        };
      };
      description = "Fontconfig settings.";
    };
  };

  impl =
    { options, ... }:
    let
      concatMapStringsSep =
        sep: f: xs:
        builtins.concatStringsSep sep (builtins.map f xs);
      optionalString = cond: s: if cond then s else "";
      boolToString = b: if b then "true" else "false";
    in
    lib.merge.attrs.recursively {
      mutators = [
        (
          if (options.enableDefaultPackages && pkgs ? dejavu_fonts) then
            {
              fonts.packages = [ pkgs.dejavu_fonts ];
            }
          else
            { }
        )

        (
          if options.fontconfig.enable then
            {
              environment.etc."fonts/fonts.conf".text = ''
                <?xml version="1.0"?>
                <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
                <fontconfig>
                  <!-- Font directories -->
                  ${concatMapStringsSep "\n" (p: "<dir>${p}/share/fonts</dir>") options.packages}
                  ${concatMapStringsSep "\n" (p: "<dir>${p}/lib/X11/fonts</dir>") options.packages}

                  <!-- Antialiasing -->
                  <match target="font">
                    <edit name="antialias" mode="assign">
                      <bool>${boolToString options.fontconfig.antialias}</bool>
                    </edit>
                  </match>

                  <!-- Hinting -->
                  <match target="font">
                    <edit name="hinting" mode="assign">
                      <bool>${boolToString options.fontconfig.hinting.enable}</bool>
                    </edit>
                    <edit name="hintstyle" mode="assign">
                      <const>hint${options.fontconfig.hinting.style}</const>
                    </edit>
                  </match>

                  <!-- Subpixel -->
                  ${optionalString (options.fontconfig.subpixel.rgba != "none") ''
                    <match target="font">
                      <edit name="rgba" mode="assign">
                        <const>${options.fontconfig.subpixel.rgba}</const>
                      </edit>
                      <edit name="lcdfilter" mode="assign">
                        <const>lcd${options.fontconfig.subpixel.lcdfilter}</const>
                      </edit>
                    </match>
                  ''}

                  ${optionalString (options.fontconfig.dpi != null) ''
                    <match target="pattern">
                      <edit name="dpi" mode="assign">
                        <double>${toString options.fontconfig.dpi}</double>
                      </edit>
                    </match>
                  ''}

                  <!-- Bitmap fonts -->
                  ${optionalString (!options.fontconfig.allowBitmaps) ''
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
                  '') options.fontconfig.defaultFonts.serif}

                  ${concatMapStringsSep "\n" (family: ''
                    <alias>
                      <family>sans-serif</family>
                      <prefer><family>${family}</family></prefer>
                    </alias>
                  '') options.fontconfig.defaultFonts.sansSerif}

                  ${concatMapStringsSep "\n" (family: ''
                    <alias>
                      <family>monospace</family>
                      <prefer><family>${family}</family></prefer>
                    </alias>
                  '') options.fontconfig.defaultFonts.monospace}

                  <!-- User config -->
                  ${optionalString options.fontconfig.includeUserConf ''
                    <include ignore_missing="yes" prefix="xdg">fontconfig/fonts.conf</include>
                  ''}

                  ${options.fontconfig.localConf}
                </fontconfig>
              '';
            }
          else
            { }
        )
      ];
    };
}
