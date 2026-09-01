# mkFlake — facade for downstream flakes consuming core-pkgs.
#
# Usage (in a consumer flake):
#
#   outputs = { core-pkgs, ... }:
#     core-pkgs.mkFlake {
#       packages = pkgs: {
#         foo = pkgs.callPackage ./foo.nix { };
#       };
#       devShells = pkgs: {
#         default = pkgs.callPackage ./shell.nix { };
#       };
#     } // {
#       # Non-per-system outputs go outside mkFlake:
#       nixosModules.default = import ./module.nix;
#     };
#
{
  config ? { },
  overlays ? [ ],
  modules ? [ ], # pkgsModules
  packages ? null,
  devShells ? null,
  checks ? null,
  formatter ? null,
  apps ? null,
  hydraJobs ? null,
  systems ? [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ],
}:

let
  genAttrs =
    names: f:
    builtins.listToAttrs (
      map (n: {
        name = n;
        value = f n;
      }) names
    );

  forAllSystems = genAttrs systems;

  legacyPackages = forAllSystems (
    system:
    import ../. {
      inherit
        system
        config
        overlays
        modules
        ;
    }
  );

  perSystem = f: forAllSystems (system: f legacyPackages.${system});

  mkApps = builtins.mapAttrs (
    _: v: {
      type = "app";
      program = v;
    }
  );

  composeManyExtensions =
    exts: final: prev:
    builtins.foldl' (acc: ext: acc // ext final prev) { } exts;
in

assert packages == null || builtins.isFunction packages;
assert devShells == null || builtins.isFunction devShells;
assert checks == null || builtins.isFunction checks;
assert formatter == null || builtins.isFunction formatter;
assert apps == null || builtins.isFunction apps;
assert hydraJobs == null || builtins.isFunction hydraJobs;

{
  inherit legacyPackages;
  ${if modules != [ ] then "pkgsModules" else null}.default = {
    imports = modules;
  };
  ${if overlays != [ ] then "overlays" else null}.default = composeManyExtensions overlays;
  ${if packages != null then "packages" else null} = perSystem packages;
  ${if devShells != null then "devShells" else null} = perSystem devShells;
  ${if checks != null then "checks" else null} = perSystem checks;
  ${if formatter != null then "formatter" else null} = perSystem formatter;
  ${if apps != null then "apps" else null} = perSystem (pkgs: mkApps (apps pkgs));
  ${if hydraJobs != null then "hydraJobs" else null} = perSystem hydraJobs;
}
