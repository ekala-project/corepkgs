# Name Service Switch configuration (/etc/nsswitch.conf)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.system.nssDatabases = {
    passwd = mkOption {
      type = types.listOf types.str;
      default = [ "files" ];
      description = "NSS passwd database entries for /etc/nsswitch.conf.";
    };

    group = mkOption {
      type = types.listOf types.str;
      default = [ "files" ];
      description = "NSS group database entries for /etc/nsswitch.conf.";
    };

    shadow = mkOption {
      type = types.listOf types.str;
      default = [ "files" ];
      description = "NSS shadow database entries for /etc/nsswitch.conf.";
    };

    hosts = mkOption {
      type = types.listOf types.str;
      default = [
        "files"
        "dns"
      ];
      description = "NSS hosts database entries for /etc/nsswitch.conf.";
    };

    services = mkOption {
      type = types.listOf types.str;
      default = [ "files" ];
      description = "NSS services database entries for /etc/nsswitch.conf.";
    };
  };

  config = {
    environment.etc."nsswitch.conf".text =
      let
        cfg = config.system.nssDatabases;
      in
      ''
        passwd:    ${concatStringsSep " " cfg.passwd}
        group:     ${concatStringsSep " " cfg.group}
        shadow:    ${concatStringsSep " " cfg.shadow}

        hosts:     ${concatStringsSep " " cfg.hosts}
        networks:  files

        services:  ${concatStringsSep " " cfg.services}
        protocols: files
        rpc:       files
        ethers:    files
      '';
  };
}
