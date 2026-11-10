# Fetch a root input of ./flake.lock without flakes, so that flake.lock stays the
# single source of truth for pins on both the flake and the non-flake paths.
#
# Nix >= 2.4 uses `builtins.fetchTree`, exactly as `nix flake` would. Nix 2.3
# lacks it, so `github` and `git` inputs fall back to `fetchTarball` and
# `fetchGit`, which produce the same store path (name "source", locked
# narHash). This file is shared verbatim across the ekala-project repos.
{
  lockFile ? ./flake.lock,
  # Where the fetchers come from; override to exercise the Nix 2.3 fallback.
  fetchers ? builtins,
}:
name:
let
  lock = builtins.fromJSON (builtins.readFile lockFile);
  # The lock node behind `input` of `node`; a list is a `follows` path from root.
  resolve =
    node: input:
    let
      ref = lock.nodes.${node}.inputs.${input};
    in
    if builtins.isList ref then builtins.foldl' resolve lock.root ref else ref;
  locked = lock.nodes.${resolve lock.root name}.locked;
  unsupported = throw "fetch-locked.nix: input '${name}' (type '${locked.type}') needs builtins.fetchTree (Nix >= 2.4)";
  fallback = {
    github = fetchers.fetchTarball {
      url = "https://${locked.host or "github.com"}/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
      sha256 = locked.narHash;
    };
    # Nix 2.3's fetchGit has no `submodules` and does not verify narHash.
    git =
      if locked.submodules or false then
        unsupported
      else
        (fetchers.fetchGit (
          { inherit (locked) url rev; } // (if locked ? ref then { inherit (locked) ref; } else { })
        )).outPath;
  };
in
if fetchers ? fetchTree then
  fetchers.fetchTree locked
else
  {
    outPath = fallback.${locked.type} or unsupported;
    inherit (locked) rev narHash;
  }
