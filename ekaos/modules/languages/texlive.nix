# Adios port of ekaos/modules/languages/texlive.nix.
# TeX Live module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "texlive";
  # NOTE: legacy used `pkgs.texlive` (a package SET, not a derivation),
  # which fails the package type check in both systems. Default to a real
  # combined scheme derivation instead.
  defaultPackage = pkgs: pkgs.texlive.combined.scheme-basic;
}
