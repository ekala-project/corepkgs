# Pins are read from flake.lock; update them with `nix flake update`.
let
  fetchLocked = import ./fetch-locked.nix { };
in
{
  lib = fetchLocked "nix-lib";
}
