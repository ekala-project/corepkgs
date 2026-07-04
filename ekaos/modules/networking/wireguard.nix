# WireGuard VPN interface configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.wireguard;

  peerSubmodule = {
    options = {
      publicKey = mkOption {
        type = types.str;
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        description = "Base64 public key of the peer.";
      };

      presharedKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing the preshared key.";
      };

      allowedIPs = mkOption {
        type = types.listOf types.str;
        example = [
          "10.0.0.0/24"
          "192.168.1.0/24"
        ];
        description = "IP ranges routed to this peer.";
      };

      endpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "vpn.example.com:51820";
        description = "Endpoint address:port of the peer.";
      };

      persistentKeepalive = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 25;
        description = "Seconds between keepalive packets. null disables.";
      };
    };
  };

  interfaceSubmodule =
    { name, config, ... }:
    {
      options = {
        ips = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "10.0.0.1/24" ];
          description = "IP addresses to assign to the WireGuard interface.";
        };

        privateKeyFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/etc/wireguard/private.key";
          description = "Path to the private key file.";
        };

        generatePrivateKeyFile = mkOption {
          type = types.bool;
          default = false;
          description = "Auto-generate a private key if the file doesn't exist.";
        };

        listenPort = mkOption {
          type = types.nullOr types.port;
          default = null;
          example = 51820;
          description = "UDP port for WireGuard to listen on.";
        };

        peers = mkOption {
          type = types.listOf (types.submodule peerSubmodule);
          default = [ ];
          description = "List of WireGuard peers.";
        };

        preSetup = mkOption {
          type = types.lines;
          default = "";
          description = "Commands to run before interface setup.";
        };

        postSetup = mkOption {
          type = types.lines;
          default = "";
          description = "Commands to run after interface setup.";
        };

        preShutdown = mkOption {
          type = types.lines;
          default = "";
          description = "Commands to run before interface teardown.";
        };

        postShutdown = mkOption {
          type = types.lines;
          default = "";
          description = "Commands to run after interface teardown.";
        };

        table = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "auto";
          description = "Routing table for WireGuard routes. null uses the main table.";
        };
      };
    };

  enabledInterfaces = filterAttrs (_: _: true) cfg.interfaces;

  # Generate a wg-quick config file
  mkWgConfig =
    name: ifCfg:
    let
      peerLines = concatMapStringsSep "\n\n" (peer: ''
        [Peer]
        PublicKey = ${peer.publicKey}
        AllowedIPs = ${concatStringsSep ", " peer.allowedIPs}
        ${optionalString (peer.endpoint != null) "Endpoint = ${peer.endpoint}"}
        ${optionalString (
          peer.persistentKeepalive != null
        ) "PersistentKeepalive = ${toString peer.persistentKeepalive}"}
        ${optionalString (peer.presharedKeyFile != null) "PresharedKey = ${peer.presharedKeyFile}"}
      '') ifCfg.peers;
    in
    ''
      [Interface]
      ${optionalString (
        ifCfg.privateKeyFile != null
      ) "PostUp = wg set %i private-key ${ifCfg.privateKeyFile}"}
      ${concatMapStringsSep "\n" (ip: "Address = ${ip}") ifCfg.ips}
      ${optionalString (ifCfg.listenPort != null) "ListenPort = ${toString ifCfg.listenPort}"}
      ${optionalString (ifCfg.table != null) "Table = ${ifCfg.table}"}
      ${optionalString (ifCfg.preSetup != "") "PreUp = ${ifCfg.preSetup}"}
      ${optionalString (ifCfg.postSetup != "") "PostUp = ${ifCfg.postSetup}"}
      ${optionalString (ifCfg.preShutdown != "") "PreDown = ${ifCfg.preShutdown}"}
      ${optionalString (ifCfg.postShutdown != "") "PostDown = ${ifCfg.postShutdown}"}

      ${peerLines}
    '';

  wireguardTools = pkgs.callPackage ../../../pkgs/wireguard-tools { };

in

{
  options.networking.wireguard = {
    enable = mkOption {
      type = types.bool;
      default = enabledInterfaces != { };
      defaultText = "true if any interfaces are defined";
      description = "Whether to enable WireGuard VPN.";
    };

    interfaces = mkOption {
      type = types.attrsOf (types.submodule interfaceSubmodule);
      default = { };
      example = literalExpression ''
        {
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
        }
      '';
      description = "WireGuard interface definitions.";
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "wireguard" ];

    environment.systemPackages = [ wireguardTools ];

    # Generate wg-quick config files
    environment.etc = listToAttrs (
      mapAttrsToList (
        name: ifCfg:
        nameValuePair "wireguard/${name}.conf" {
          text = mkWgConfig name ifCfg;
          mode = "0600";
        }
      ) enabledInterfaces
    );

    # Set up WireGuard interfaces during activation
    system.activationScripts.wireguard = stringAfter [ "etc" "modprobe" ] ''
      ${concatStringsSep "\n" (
        mapAttrsToList (name: ifCfg: ''
          # WireGuard interface: ${name}
          ${optionalString ifCfg.generatePrivateKeyFile ''
            if [ ! -f "${ifCfg.privateKeyFile}" ]; then
              echo "Generating WireGuard private key for ${name}..."
              mkdir -p $(dirname "${ifCfg.privateKeyFile}")
              ${wireguardTools}/bin/wg genkey > "${ifCfg.privateKeyFile}"
              chmod 600 "${ifCfg.privateKeyFile}"
            fi
          ''}
          echo "Setting up WireGuard interface ${name}..."
          ${wireguardTools}/bin/wg-quick up /etc/wireguard/${name}.conf 2>/dev/null || \
            ${wireguardTools}/bin/wg-quick down ${name} 2>/dev/null; \
            ${wireguardTools}/bin/wg-quick up /etc/wireguard/${name}.conf || true
        '') enabledInterfaces
      )}
    '';
  };
}
