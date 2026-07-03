# Cross-platform declarative file state management
# Defines tmpfiles.rules options consumed by service manager modules
# Replaces the systemd-specific systemd.tmpfiles module
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  tmpfilesOpts = import ../../../services/lib/tmpfiles-options.nix { inherit lib; };
  tmpfilesModule = import ../../../services/lib/tmpfiles-module.nix { inherit lib pkgs; };
  shellTranslate = import ../../../services/lib/tmpfiles-shell-translate.nix { inherit lib pkgs; };
  systemdTranslate = import ../../../services/lib/tmpfiles-systemd-translate.nix { inherit lib pkgs; };

  cfg = config.tmpfiles;

in

{
  options.tmpfiles = {
    rules = mkOption {
      type = types.listOf (types.submodule tmpfilesOpts.ruleOptions);
      default = [ ];
      example = literalExpression ''
        [
          { type = "directory"; path = "/var/lib/myapp"; mode = "0755"; user = "myapp"; group = "myapp"; }
          { type = "file"; path = "/var/lib/myapp/config"; mode = "0644"; content = "key=value"; }
          { type = "symlink"; path = "/var/run/mylink"; target = "/actual/path"; }
        ]
      '';
      description = ''
        Cross-platform declarative file/directory state rules.
        Automatically translated to systemd tmpfiles.d format,
        or shell scripts for runit/launchd/BSD.
      '';
    };
  };

  config = mkIf (cfg.rules != [ ]) {
    # Systemd: generate tmpfiles.d config and run systemd-tmpfiles
    environment.etc = mkIf (config.serviceManager.systemd.enable or false) {
      "tmpfiles.d/ekaos.conf".text = systemdTranslate.toTmpfilesConf cfg.rules;
    };

    # For all platforms: run shell-based tmpfiles during activation
    # On systemd, systemd-tmpfiles handles it natively, but the shell
    # fallback ensures it works during activation before systemd starts
    system.activationScripts.tmpfiles = stringAfter [
      "etc"
      "users"
    ] (shellTranslate.toShellCommands cfg.rules);
  };
}
