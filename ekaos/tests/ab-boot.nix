# A/B boot test
# Validates boot counting on BLS entries and the bless-boot service.
# Tests that creating a new generation produces a boot-counted entry
# and that the bless-boot script removes the suffix after a health check.

{ pkgs, ... }:

{
  name = "ab-boot";

  meta.description = "Test A/B boot with boot counting and generation blessing";

  nodes = {
    machine =
      { config, pkgs, ... }:
      {
        boot.kernelPackages = pkgs.linuxPackages;
        boot.loader.systemd-boot.enable = true;

        boot.ab = {
          enable = true;
          bootCountTriesLeft = 3;
          healthCheck = {
            command = "true"; # Always pass in test
            timeout = 30;
          };
        };

        virtualisation.enable = true;
        virtualisation.enableNetwork = true;
      };
  };

  testScript =
    nodes:
    let
      installerPath = nodes.machine.config.system.build.installBootLoader;
      toplevelPath = nodes.machine.config.system.build.toplevel;
    in
    ''
      machine.start()
      machine.wait_for_unit("multi-user.target")

      # -- Booted and current system should match at boot --
      machine.succeed("test -L /run/booted-system")
      machine.succeed("test -L /run/current-system")
      booted = machine.succeed("readlink /run/booted-system").strip()
      current = machine.succeed("readlink /run/current-system").strip()
      assert booted == current, (
          f"booted ({booted}) != current ({current}) at boot time"
      )
      print(f"System: {booted}")

      # -- Bless-boot service should run and complete for gen 1 --
      machine.succeed("systemctl cat ekaos-bless-boot.service")
      machine.wait_for_unit("ekaos-bless-boot.service")
      print("ekaos-bless-boot.service completed for generation 1")

      # -- After blessing gen 1, no boot counting suffixes should remain --
      entries = machine.succeed("ls /boot/loader/entries/").strip()
      print(f"Boot entries after gen 1 blessing: {entries}")
      assert "+" not in entries, f"boot counting suffix still present after blessing gen 1: {entries}"

      # -- Create generation 2 and install its boot entry --
      # Register the same system closure as a new generation.
      # nix-env --set always increments the generation number.
      machine.succeed("nix-env -p /nix/var/nix/profiles/system --set ${toplevelPath}")

      # Verify generation 2 was created
      machine.succeed("test -L /nix/var/nix/profiles/system-2-link")
      print("Generation 2 created")

      # Run the bootloader installer to write new boot entries.
      # This creates a boot-counted entry (+3-0) for the new default generation.
      machine.succeed("NIXOS_INSTALL_BOOTLOADER=1 ${installerPath} ${toplevelPath}")

      # -- The new generation's entry should have a boot counting suffix --
      entries = machine.succeed("ls /boot/loader/entries/").strip()
      print(f"Boot entries after gen 2 install: {entries}")
      assert "+3-0" in entries, f"expected boot counting suffix +3-0 in entries: {entries}"

      # -- Simulate booting into generation 2 by pointing /run/booted-system --
      # In a real boot, systemd-boot loads the new generation and the initrd
      # sets /run/booted-system. Here we fake it so the bless-boot script
      # can find the matching entry.
      machine.succeed("ln -sfn ${toplevelPath} /run/booted-system")

      # -- Run the bless-boot script to mark generation 2 as good --
      machine.succeed("${nodes.machine.config.services.ekaos-bless-boot.command}")

      # -- After blessing, the boot counting suffix should be removed --
      entries = machine.succeed("ls /boot/loader/entries/").strip()
      print(f"Boot entries after gen 2 blessing: {entries}")
      assert "+" not in entries, f"boot counting suffix still present after blessing gen 2: {entries}"

      machine.shutdown()
    '';
}
