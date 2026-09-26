# Adios port of ekaos/modules/network-interfaces.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    # Legacy path: networking.interfaces.
    interfaces = {
      type = types.attrsOf types.attrs;
      # TODO(adios-cutover): submodule validation lost. Each entry is a raw
      # attrset supporting: ipv4.addresses / ipv6.addresses (lists of
      # { address (string), prefixLength (int; v4 0-32, v6 0-128) }),
      # useDHCP (null or bool, default null = inherit networking.useDHCP),
      # mtu (null or positive int, default null).
      default = { };
      description = ''
        Configuration for network interfaces.

        Each attribute defines settings for a specific interface.
        Interfaces can have static IP addresses, use DHCP, or both.
      '';
    };
  };

  inputs = {
    networking.from = { root }: root.networking;
    # TODO(adios-cutover): provides systemd.package (defined in
    # ekaos/modules/system/toplevel.nix); flat leaf name pending the
    # system/toplevel port — full legacy path used below.
    systemd.from = { root }: root.system.toplevel;
  };

  impl =
    { options, inputs }:
    let
      # Generate systemd-networkd .network file content. `or` fallbacks
      # reproduce the legacy submodule defaults (validation is lost, see TODO
      # above).
      mkNetworkUnit =
        iface: icfg:
        let
          v4Addrs = (icfg.ipv4 or { }).addresses or [ ];
          v6Addrs = (icfg.ipv6 or { }).addresses or [ ];
          useDHCP = if (icfg.useDHCP or null) != null then icfg.useDHCP else inputs.networking.useDHCP;
          hasStaticAddrs = v4Addrs != [ ] || v6Addrs != [ ];
        in
        ''
          [Match]
          Name=${iface}

          [Network]
          ${if useDHCP then "DHCP=yes" else ""}
          ${builtins.concatStringsSep "\n" (
            builtins.map (addr: "Address=${addr.address}/${toString addr.prefixLength}") v4Addrs
          )}
          ${builtins.concatStringsSep "\n" (
            builtins.map (addr: "Address=${addr.address}/${toString addr.prefixLength}") v6Addrs
          )}
          ${
            if inputs.networking.defaultGateway != null && hasStaticAddrs then
              "Gateway=${inputs.networking.defaultGateway}"
            else
              ""
          }
          ${
            if inputs.networking.defaultGateway6 != null && hasStaticAddrs then
              "Gateway=${inputs.networking.defaultGateway6}"
            else
              ""
          }

          [Link]
          ${if (icfg.mtu or null) != null then "MTUBytes=${toString icfg.mtu}" else ""}
          RequiredForOnline=no
        '';

      filterAttrs =
        pred: set:
        builtins.listToAttrs (
          builtins.map (n: {
            name = n;
            value = set.${n};
          }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
        );

      # Only generate configs for interfaces that have been explicitly
      # configured.
      configuredInterfaces = filterAttrs (
        name: icfg:
        ((icfg.ipv4 or { }).addresses or [ ]) != [ ]
        || ((icfg.ipv6 or { }).addresses or [ ]) != [ ]
        || (icfg.useDHCP or null) != null
        || (icfg.mtu or null) != null
      ) options.interfaces;
    in
    if configuredInterfaces == { } then
      { }
    else
      {
        environment.etc = lib.merge.attrs.recursively {
          mutators = [
            (builtins.listToAttrs (
              builtins.map (iface: {
                name = "systemd/network/50-${iface}.network";
                value = {
                  text = mkNetworkUnit iface configuredInterfaces.${iface};
                };
              }) (builtins.attrNames configuredInterfaces)
            ))

            {
              "systemd/system/systemd-networkd.service".source =
                "${inputs.systemd.systemd.package}/lib/systemd/system/systemd-networkd.service";
            }
          ];
        };

        # TODO(adios-cutover): stringAfter [ "etc" ] ordering dropped.
        system.activationScripts.networkd = ''
          # Enable systemd-networkd
          echo "Enabling systemd-networkd..."
          mkdir -p /etc/systemd/system/multi-user.target.wants
          ln -sf ../systemd-networkd.service \
                 /etc/systemd/system/multi-user.target.wants/systemd-networkd.service
        '';
      };
}
