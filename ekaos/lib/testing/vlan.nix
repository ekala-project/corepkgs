# Shared test network for multi-node ekaosTest runs
#
# The driver runs a vde_switch and passes its socket to each VM script via
# EKAOS_TEST_VDE_SOCKET. Every node gets a second NIC on that switch with a
# fixed MAC and the address 192.168.1.<index>, matching the /etc/hosts
# entries generated in nodes.nix. The user-mode NIC is left untouched.
{ index }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  hex = lib.toLower (lib.toHexString index);
  mac = "52:54:00:12:01:${lib.fixedWidthString 2 "0" hex}";
  address = "192.168.1.${toString index}";
in
{
  assertions = [
    {
      assertion = index >= 1 && index <= 254;
      message = "ekaosTest supports at most 254 nodes";
    }
  ];

  virtualisation.qemuOptions = ''
    if [ -n "''${EKAOS_TEST_VDE_SOCKET:-}" ]; then
      QEMU_OPTS+=(
        -device virtio-net-pci,netdev=vlan1,mac=${mac}
        -netdev vde,id=vlan1,sock="$EKAOS_TEST_VDE_SOCKET"
      )
    fi
  '';

  boot.kernelParams = [ "systemd.wants=ekaos-test-vlan.service" ];

  systemd.services.ekaos-test-vlan = {
    description = "ekaosTest shared network (${address})";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    script = ''
      export PATH=${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.iproute2
        ]
      }

      iface=
      for _ in $(seq 1 100); do
        for dev in /sys/class/net/*; do
          if [ "$(cat "$dev/address" 2>/dev/null)" = "${mac}" ]; then
            iface=''${dev##*/}
            break 2
          fi
        done
        sleep 0.1
      done

      if [ -z "$iface" ]; then
        echo "ekaos-test-vlan: no interface with MAC ${mac}; not attached" >&2
        exit 0
      fi

      ip link set dev "$iface" up
      ip addr replace ${address}/24 dev "$iface"
      echo "ekaos-test-vlan: $iface is ${address}"
    '';
  };
}
