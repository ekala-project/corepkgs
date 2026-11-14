# Static user and group ids for the accounts ekaos modules create
#
# /etc/passwd and /etc/group are generated at evaluation time, with no
# allocation state on disk, so a system account's id has to be fixed in
# the configuration: one that changed between generations would leave
# the service's files owned by someone else.
#
# Numbers are NixOS's where it has (or had) one, so state moved from a
# NixOS machine keeps its ownership. Ids NixOS never assigned are taken
# from 900 upward, above everything NixOS uses below 1000.
{ lib, ... }:

{
  options.ids = {
    uids = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      internal = true;
      description = "The user ids used by ekaos modules.";
    };

    gids = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      internal = true;
      description = "The group ids used by ekaos modules.";
    };
  };

  config.ids = {
    uids = {
      bind = 53; # NixOS's, before it went dynamic
      postgres = 71;
      nix-ssh = 104; # NixOS's, before it went dynamic
      dnsmasq = 141; # NixOS's, before it went dynamic
      tss = 176; # NixOS's, before it went dynamic
      redis = 181; # NixOS's, before it went dynamic
      unbound = 900;
      fwupd-refresh = 901;
    };

    gids = {
      bind = 53;
      postgres = 71;
      docker = 131;
      dnsmasq = 141;
      tss = 176;
      redis = 181;
      unbound = 900;
      fwupd-refresh = 901;
      libvirt = 902;
      i2c = 903;
    };
  };
}
