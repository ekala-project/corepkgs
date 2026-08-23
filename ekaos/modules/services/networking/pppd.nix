# PPP daemon (pppd) service module
# Provides point-to-point protocol connections
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.pppd;
in

{
  options = {
    services.pppd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the PPP daemon.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.ppp;
        defaultText = literalExpression "pkgs.ppp";
        description = "The ppp package to use.";
      };

      peers = mkOption {
        default = { };
        description = "PPP peer configurations.";
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              options = {
                name = mkOption {
                  type = types.str;
                  default = name;
                  example = "dialup";
                  description = "Name of the PPP peer.";
                };

                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether to enable this PPP peer.";
                };

                autostart = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether the PPP session starts automatically at boot.";
                };

                config = mkOption {
                  type = types.lines;
                  default = "";
                  description = ''
                    pppd configuration for this peer.
                    See pppd(8) for available options.
                  '';
                };
              };
            }
          )
        );
      };
    };
  };

  config =
    let
      enabledPeers = filter (f: f.enable) (attrValues cfg.peers);

      mkEtc = peerCfg: {
        name = "ppp/peers/${peerCfg.name}";
        value.text = peerCfg.config;
      };

      mkService = peerCfg: {
        name = "pppd-${peerCfg.name}";
        value = {
          enable = true;
          description = "PPP connection ${peerCfg.name}";
          command = "${getBin cfg.package}/bin/pppd";
          args = [
            "call"
            peerCfg.name
            "up_sdnotify"
            "nolog"
          ];
          user = "root";
          restartPolicy = "always";
          environment = {
            LD_PRELOAD = "${pkgs.libredirect}/lib/libredirect.so";
            NIX_REDIRECTS = "/var/run=/run/pppd";
          };

          systemd = {
            after = [ "network-pre.target" ];
            before = [ "network.target" ];
            wants = [ "network.target" ];
            wantedBy = mkIf peerCfg.autostart [ "multi-user.target" ];
            serviceConfig = {
              Type = "notify";
              Restart = "always";
              RestartSec = 5;
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = true;
              ProtectSystem = "strict";
              RuntimeDirectory = "pppd";
              RuntimeDirectoryPreserve = true;
            };
          };
        };
      };
    in
    mkIf cfg.enable {
      environment.etc = listToAttrs (map mkEtc enabledPeers);
      services = listToAttrs (map mkService enabledPeers);
      environment.systemPackages = [ cfg.package ];
    };
}
