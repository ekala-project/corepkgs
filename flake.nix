{
  description = "Core packages flake";

  inputs = {
    # For bootstrapping
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      systems,
      nixpkgs,
      treefmt-nix,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (import systems);
      mkTreefmt =
        pkgs:
        let
          fmt = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.keep-sorted = {
              enable = true;
              includes = [ "*.nix" ];
            };
          };
        in
        fmt.config.build.wrapper;
    in
    {
      legacyPackages = forAllSystems (
        system:
        import ./. {
          inherit system;
        }
      );
      formatter = forAllSystems (system: mkTreefmt nixpkgs.legacyPackages.${system});
      nixConfig = {
        extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
        extra-trusted-public-keys = [
          "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
        ];
      };
      mkFlake = import ./lib/mk-flake.nix;
    };
}
