{
  lib,
  buildEnv,
  nix-prefetch-cvs,
  nix-prefetch-darcs,
  nix-prefetch-git,
  nix-prefetch-hg,
  nix-prefetch-svn,
  nix-prefetch-pijul,
}:
buildEnv {
  name = "nix-prefetch-scripts";

  paths = [
    nix-prefetch-cvs
    nix-prefetch-darcs
    nix-prefetch-git
    nix-prefetch-hg
    nix-prefetch-svn
    nix-prefetch-pijul
  ];

  meta = {
    description = "Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes";
    platforms = lib.platforms.unix;
  };
}
