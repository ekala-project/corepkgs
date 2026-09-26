# Adios port of ekaos/modules/networking/wireguard.nix.
#
# Tree path: networking/wireguard is parent.networking.wireguard.
# Self-contained; no cross-module reads. The wg-quick config builder and
# the wireguard-tools package close over pkgs in the top-level let.
# TODO(adios-cutover): interfaces is types.attrsOf types.attrs; legacy
# interface/peer submodule validation lost. Per-interface defaults
# (ips=[], privateKeyFile=null, generatePrivateKeyFile=false,
# listenPort=null, peers=[], pre/postSetup/Shutdown="", table=null) and
# per-peer optionals are applied via `or` fallbacks in impl.
{ types, pkgs, ... }:

let
  mapAttrsToList = f: attrs: builtins.map (n: f n attrs.${n}) (builtins.attrNames attrs);

  wireguardTools = pkgs.callPackage ../../../../pkgs/wireguard-tools { };

  # Generate a wg-quick config file
  mkWgConfig =
    name: ifCfg:
    let
      peers = ifCfg.peers or [ ];
      peerLines = builtins.concatStringsSep "\n\n" (
        builtins.map (peer: ''
          [Peer]
          PublicKey = ${peer.publicKey}
          AllowedIPs = ${builtins.concatStringsSep ", " peer.allowedIPs}
          ${if (peer.endpoint or null) != null then "Endpoint = ${peer.endpoint}" else ""}
          ${
            if (peer.persistentKeepalive or null) != null then
              "PersistentKeepalive = ${toString peer.persistentKeepalive}"
            else
              ""
          }
          ${if (peer.presharedKeyFile or null) != null then "PresharedKey = ${peer.presharedKeyFile}" else ""}
        '') peers
      );
      privateKeyFile = ifCfg.privateKeyFile or null;
      ips = ifCfg.ips or [ ];
      listenPort = ifCfg.listenPort or null;
      table = ifCfg.table or null;
      preSetup = ifCfg.preSetup or "";
      postSetup = ifCfg.postSetup or "";
      preShutdown = ifCfg.preShutdown or "";
      postShutdown = ifCfg.postShutdown or "";
    in
    ''
      [Interface]
      ${if privateKeyFile != null then "PostUp = wg set %i private-key ${privateKeyFile}" else ""}
      ${builtins.concatStringsSep "\n" (builtins.map (ip: "Address = ${ip}") ips)}
      ${if listenPort != null then "ListenPort = ${toString listenPort}" else ""}
      ${if table != null then "Table = ${table}" else ""}
      ${if preSetup != "" then "PreUp = ${preSetup}" else ""}
      ${if postSetup != "" then "PostUp = ${postSetup}" else ""}
      ${if preShutdown != "" then "PreDown = ${preShutdown}" else ""}
      ${if postShutdown != "" then "PostDown = ${postShutdown}" else ""}

      ${peerLines}
    '';
in

{
  options = {
    enable = {
      type = types.bool;
      # Legacy: default = enabledInterfaces != { } ("true if any interfaces
      # are defined").
      defaultFunc = { inputs, options }: options.interfaces != { };
      description = "Whether to enable WireGuard VPN.";
    };

    interfaces = {
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        wg0 = {
          ips = [ "10.0.0.1/24" ];
          listenPort = 51820;
          privateKeyFile = "/etc/wireguard/private.key";
          generatePrivateKeyFile = true;
          peers = [
            {
              publicKey = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
              allowedIPs = [ "10.0.0.0/24" ];
              endpoint = "vpn.example.com:51820";
              persistentKeepalive = 25;
            }
          ];
        };
      };
      description = ''
        WireGuard interface definitions. Each interface may set ips,
        privateKeyFile, generatePrivateKeyFile, listenPort, peers
        (publicKey, allowedIPs, endpoint, persistentKeepalive,
        presharedKeyFile), preSetup, postSetup, preShutdown,
        postShutdown, table.
      '';
    };
  };

  impl =
    { options, inputs }:
    let
      # Legacy: filterAttrs (_: _: true) — identity over all interfaces.
      enabledInterfaces = options.interfaces;
    in
    if !options.enable then
      { }
    else
      {
        boot.kernelModules = [ "wireguard" ];

        environment.systemPackages = [ wireguardTools ];

        # Generate wg-quick config files
        environment.etc = builtins.listToAttrs (
          mapAttrsToList (name: ifCfg: {
            name = "wireguard/${name}.conf";
            value = {
              text = mkWgConfig name ifCfg;
              mode = "0600";
            };
          }) enabledInterfaces
        );

        # Set up WireGuard interfaces during activation
        system.activationScripts.wireguard = {
          deps = [
            "etc"
            "modprobe"
          ];
          text = ''
            ${builtins.concatStringsSep "\n" (
              mapAttrsToList (name: ifCfg: ''
                # WireGuard interface: ${name}
                ${
                  if (ifCfg.generatePrivateKeyFile or false) then
                    ''
                      if [ ! -f "${ifCfg.privateKeyFile}" ]; then
                        echo "Generating WireGuard private key for ${name}..."
                        mkdir -p $(dirname "${ifCfg.privateKeyFile}")
                        ${wireguardTools}/bin/wg genkey > "${ifCfg.privateKeyFile}"
                        chmod 600 "${ifCfg.privateKeyFile}"
                      fi
                    ''
                  else
                    ""
                }
                echo "Setting up WireGuard interface ${name}..."
                ${wireguardTools}/bin/wg-quick up /etc/wireguard/${name}.conf 2>/dev/null || \
                  ${wireguardTools}/bin/wg-quick down ${name} 2>/dev/null; \
                  ${wireguardTools}/bin/wg-quick up /etc/wireguard/${name}.conf || true
              '') enabledInterfaces
            )}
          '';
        };
      };
}
