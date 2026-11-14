# Multi-node test - validates the shared test network
# Two nodes reach each other by name over the VDE switch the driver starts

{ pkgs, ... }:

let
  node =
    { pkgs, ... }:
    {
      virtualisation.enable = true;
      environment.systemPackages = [
        pkgs.iproute2
        pkgs.iputils
      ];
    };
in
{
  name = "multi-node";

  meta = {
    description = "Test that ekaos test nodes share a network and resolve each other by name";
    timeout = 600;
  };

  nodes = {
    alice = node;
    bob = node;
  };

  testScript = ''
    start_all()

    # Each node has the shared-network address its peers' /etc/hosts
    # entries point at
    for m, address in ((alice, "192.168.1.1"), (bob, "192.168.1.2")):
        m.wait_for_unit("multi-user.target")
        m.wait_for_unit("ekaos-test-vlan.service")
        addrs = m.succeed("ip -4 -o addr show to 192.168.1.0/24")
        print(addrs)
        assert f" {address}/24 " in addrs, f"{m.name} has {addrs!r}, expected {address}/24"
        m.succeed("grep -qE '^192\\.168\\.1\\.1[[:space:]]+alice$' /etc/hosts")
        m.succeed("grep -qE '^192\\.168\\.1\\.2[[:space:]]+bob$' /etc/hosts")

    alice.succeed("ping -c 3 -W 5 bob")
    bob.succeed("ping -c 3 -W 5 alice")

    alice.shutdown()
    bob.shutdown()
  '';
}
