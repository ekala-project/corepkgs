# Adios port of ekaos/modules/services/hardware/udev.nix.
{ types, pkgs, ... }:

{
  options = {
    packages = {
      type = types.listOf types.pathLike;
      default = [ ];
      description = ''
        List of packages containing udev rules.
        All files found in «pkg»/etc/udev/rules.d and
        «pkg»/lib/udev/rules.d will be included.
      '';
    };

    extraRules = {
      type = types.string;
      default = "";
      description = "Additional udev rules to install.";
    };
  };

  impl =
    { options, ... }:
    if (options.packages == [ ] && options.extraRules == "") then
      { }
    else
      let
        combinedRules = pkgs.runCommand "udev-rules" { preferLocalBuild = true; } ''
          mkdir -p $out/etc/udev/rules.d

          ${builtins.concatStringsSep "" (
            builtins.map (pkg: ''
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
            '') options.packages
          )}

          ${
            if options.extraRules != "" then
              ''
                cat > $out/etc/udev/rules.d/99-local.rules <<'RULES'
                ${options.extraRules}
                RULES
              ''
            else
              ""
          }
        '';
      in
      {
        environment.etc."udev/rules.d".source = "${combinedRules}/etc/udev/rules.d";
      };
}
