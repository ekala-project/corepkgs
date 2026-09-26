# Adios port of ekaos/modules/tasks/tmpfiles.nix.
#
# Tree path: tasks/tmpfiles is parent.tasks.tmpfiles.
#
# Cross-platform declarative file state management: defines tmpfiles.rules
# consumed by the service-manager modules. When the systemd manager is
# enabled (inputs.systemdMgr, parent.service-managers.systemd), a
# tmpfiles.d config is generated; a shell fallback always runs during
# activation (it works before systemd starts).
#
# TODO(adios-cutover): HELPER GAP (load-bearing). services/lib/
# tmpfiles-{options,module,shell-translate,systemd-translate}.nix are
# nixpkgs-lib-based and need adios-aware rewrites owned outside this
# batch. The imports below keep their legacy call shape with adjusted
# relative paths; `lib` here is adios.lib, so evaluation fails until the
# helpers are rewritten. Rule shape (from ruleOptions): type enum
# directory/file/symlink/remove/recursive-permissions, path, mode
# (default "0755"), user/group (default root), age, content, target.
# TODO(adios-cutover): rules is types.listOf types.attrs; per-rule field
# validation lost.
{
  types,
  lib,
  pkgs,
  ...
}:

let
  tmpfilesOpts = import ../../../../services/lib/tmpfiles-options.nix { inherit lib; };
  tmpfilesModule = import ../../../../services/lib/tmpfiles-module.nix { inherit lib pkgs; };
  shellTranslate = import ../../../../services/lib/tmpfiles-shell-translate.nix { inherit lib pkgs; };
  systemdTranslate = import ../../../../services/lib/tmpfiles-systemd-translate.nix {
    inherit lib pkgs;
  };
  _ruleOptions = tmpfilesOpts.ruleOptions;
  _module = tmpfilesModule;
in

{
  options = {
    rules = {
      type = types.listOf types.attrs;
      default = [ ];
      example = [
        {
          type = "directory";
          path = "/var/lib/myapp";
          mode = "0755";
          user = "myapp";
          group = "myapp";
        }
        {
          type = "file";
          path = "/var/lib/myapp/config";
          mode = "0644";
          content = "key=value";
        }
        {
          type = "symlink";
          path = "/var/run/mylink";
          target = "/actual/path";
        }
      ];
      description = ''
        Cross-platform declarative file/directory state rules.
        Automatically translated to systemd tmpfiles.d format,
        or shell scripts for runit/launchd/BSD.
      '';
    };
  };

  inputs = {
    systemdMgr.from = { root }: root."service-managers".systemd;
  };

  impl =
    { options, inputs }:
    if options.rules == [ ] then
      { }
    else
      (
        # Systemd: generate tmpfiles.d config and run systemd-tmpfiles
        if (inputs.systemdMgr.enable or false) then
          {
            environment.etc."tmpfiles.d/ekaos.conf".text = systemdTranslate.toTmpfilesConf options.rules;
          }
        else
          { }
      )
      // {
        # For all platforms: run shell-based tmpfiles during activation
        # On systemd, systemd-tmpfiles handles it natively, but the shell
        # fallback ensures it works during activation before systemd starts
        system.activationScripts.tmpfiles = {
          deps = [
            "etc"
            "users"
          ];
          text = shellTranslate.toShellCommands options.rules;
        };
      };
}
