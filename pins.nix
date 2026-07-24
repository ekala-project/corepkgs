let
  # Inherit pinning from flake.lock
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  libInfo = lock.nodes.lib.locked;
in
{
  lib = builtins.fetchTree {
    inherit (libInfo)
      type
      owner
      repo
      narHash
      rev
      ;
  };
}
