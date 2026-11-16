{
  # iets evaluates in pure mode, where `builtins.currentSystem` does not
  # exist; `iets eval-jobs --argstr system ...` overrides this default.
  system ? "x86_64-linux",
}:
let
  allPkgs = import ./packages.nix { inherit system; };
in
allPkgs.buildable
