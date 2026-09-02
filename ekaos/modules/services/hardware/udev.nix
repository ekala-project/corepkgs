# udev rules aggregation
#
# Provides services.udev.packages for collecting udev rules from packages.
# Packages listed here will have their rules from
#   «pkg»/etc/udev/rules.d and «pkg»/lib/udev/rules.d
# installed into the system.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.udev;

  # Combine udev rules from all listed packages into a single directory
  combinedRules = pkgs.runCommand "udev-rules" { preferLocalBuild = true; } ''
    mkdir -p $out/etc/udev/rules.d

    ${concatMapStrings (pkg: ''
      if [ -d "${pkg}/etc/udev/rules.d" ]; then
        for f in "${pkg}"/etc/udev/rules.d/*; do
          [ -e "$f" ] && ln -sf "$f" "$out/etc/udev/rules.d/$(basename "$f")"
        done
      fi
      if [ -d "${pkg}/lib/udev/rules.d" ]; then
        for f in "${pkg}"/lib/udev/rules.d/*; do
          [ -e "$f" ] && ln -sf "$f" "$out/etc/udev/rules.d/$(basename "$f")"
        done
      fi
    '') cfg.packages}

    ${optionalString (cfg.extraRules != "") ''
      cat > $out/etc/udev/rules.d/99-local.rules <<'RULES'
      ${cfg.extraRules}
      RULES
    ''}
  '';
in

{
  options.services.udev = {
    packages = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        List of packages containing udev rules.
        All files found in «pkg»/etc/udev/rules.d and
        «pkg»/lib/udev/rules.d will be included.
      '';
    };

    extraRules = mkOption {
      type = types.lines;
      default = "";
      description = "Additional udev rules to install.";
    };
  };

  config = mkIf (cfg.packages != [ ] || cfg.extraRules != "") {
    environment.etc."udev/rules.d".source = "${combinedRules}/etc/udev/rules.d";
  };
}
