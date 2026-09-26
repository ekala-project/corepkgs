# Adios port of ekaos/modules/services/networking/pppd.nix.
# TODO(adios-cutover): peers used attrsOf (submodule ...) with per-peer
# defaults (name=key, enable/autostart=true, config=""); submodule validation
# lost, defaults re-applied via `or` fallbacks in impl.
# TODO(adios-cutover): the legacy mkService helper is dead code (defined but
# never wired into the config); it is preserved verbatim for fidelity.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the PPP daemon.";
    };

    package = {
      type = types.derivation;
      default = pkgs.ppp;
      description = "The ppp package to use.";
    };

    peers = {
      type = types.attrsOf types.attrs;
      default = { };
      description = "PPP peer configurations.";
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        peers = options.peers or { };
        withNames = builtins.map (n: peers.${n} // { name = peers.${n}.name or n; }) (
          builtins.attrNames peers
        );
        enabledPeers = builtins.filter (f: (f.enable or true)) withNames;

        mkEtc = peerCfg: {
          name = "ppp/peers/${peerCfg.name}";
          value.text = peerCfg.config or "";
        };

        mkService = peerCfg: {
          name = "pppd-${peerCfg.name}";
          value = {
            enable = true;
            description = "PPP connection ${peerCfg.name}";
            # Local replacement for lib.getBin (bin output or package itself).
            command = "${options.package.bin or options.package}/bin/pppd";
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
              wantedBy = if (peerCfg.autostart or true) then [ "multi-user.target" ] else [ ];
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
      {
        environment.etc = builtins.listToAttrs (builtins.map mkEtc enabledPeers);
        environment.systemPackages = [ options.package ];
      };
}
