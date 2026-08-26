{
  lib,
  variants,
}:
{
  stable = "v2_34";
  latest = "v2_35";
}
// lib.listToAttrs (
  map (
    minor: lib.nameValuePair "v2_${toString minor}" (throw "nix v2.${toString minor} has been removed")
  ) (lib.range 4 27)
)
// {
  minimum = throw "nix minimum has been removed. Use a specific version.";
  unstable = throw "nix unstable has been removed. Use latest or git.";
}
