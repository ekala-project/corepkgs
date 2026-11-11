# Units and unit settings the ekaos switch engine relies on
#
# - switch-engine settings for upstream units that must not be restarted
#   (or must be handled specially) on switch, mirroring nixpkgs'
#   nixos/modules/system/boot/systemd.nix
# - sysinit-reactivation.target, which the engine restarts after activation
#   so units ordered before sysinit.target are re-run in order
# - systemd-tmpfiles-resetup.service, so tmpfiles changes apply on switch
{
  config,
  lib,
  pkgs,
  ...
}:

let
  tmpfilesSystemd = import ../../../services/lib/tmpfiles-systemd-translate.nix {
    inherit lib pkgs;
  };
in
{
  config = lib.mkIf (config.serviceManager.systemd.enable or false) {
    systemd.switchOverrides = {
      "systemd-backlight@.service".restartIfChanged = false;
      "systemd-fsck@.service".restartIfChanged = false;
      "systemd-makefs@.service".restartIfChanged = false;
      "systemd-mkswap@.service".restartIfChanged = false;
      "modprobe@.service".restartIfChanged = false;
      "systemd-random-seed.service".restartIfChanged = false;
      "systemd-remount-fs.service".restartIfChanged = false;
      "systemd-update-utmp.service".restartIfChanged = false;
      "local-fs.target".stopOnReconfiguration = true;
      "remote-fs.target".stopOnReconfiguration = true;
    };

    environment.etc."systemd/system/sysinit-reactivation.target".text = ''
      [Unit]
      Description=Reactivate sysinit units
    '';

    # Kept aligned with upstream systemd-tmpfiles-setup.service, minus --boot,
    # which must only run once per boot.
    systemd.services.systemd-tmpfiles-resetup = {
      description = "Re-setup tmpfiles on a system that is already running";
      requiredBy = [ "sysinit-reactivation.target" ];
      after = [
        "local-fs.target"
        "systemd-sysusers.service"
        "systemd-journald.service"
      ];
      before = [
        "sysinit-reactivation.target"
        "shutdown.target"
      ];
      conflicts = [ "shutdown.target" ];
      restartTriggers =
        config.systemd.tmpfiles.packages
        ++ lib.optional (config.tmpfiles.rules != [ ]) (
          tmpfilesSystemd.toTmpfilesConf config.tmpfiles.rules
        );
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "${config.systemd.package}/bin/systemd-tmpfiles --create --remove --exclude-prefix=/dev";
        SuccessExitStatus = "DATAERR CANTCREAT";
      };
    };
  };
}
