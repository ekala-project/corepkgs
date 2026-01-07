lib: final: prev:
let
  inherit (final) pkgs;
  # Removing recurseForDerivation prevents derivations of aliased attribute set
  # to appear while listing all the packages available.
  removeRecurseForDerivations =
    alias:
    if alias.recurseForDerivations or false then
      lib.removeAttrs alias [ "recurseForDerivations" ]
    else
      alias;

  # Make sure that we are not shadowing something from top-level.nix.
  checkInPkgs =
    n: alias: if builtins.hasAttr n prev then abort "Alias ${n} is still in top-level.nix" else alias;

  mapAliases =
    aliases: lib.mapAttrs (n: alias: removeRecurseForDerivations (checkInPkgs n alias)) aliases;
in
with pkgs;
mapAliases {
  # keep-sorted start

  # keep-sorted end
}
