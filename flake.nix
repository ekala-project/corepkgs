{
  description = "Core packages flake";

  inputs = {
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-lib.url = "github:ekala-project/nix-lib";
  };

  outputs =
    {
      self,
      systems,
      nix-lib,
      treefmt-nix,
      ...
    }:
    let
      forAllSystems = nix-lib.lib.genAttrs (import systems);
      mkTreefmt =
        pkgs:
        let
          fmt = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.nixfmt.package = pkgs.nixfmt-rs;
            programs.keep-sorted = {
              enable = true;
              includes = [
                "*.nix"
                "maintainers/scripts/sync-with-nixpkgs/script.py"
              ];
            };
          };
        in
        fmt.config.build.wrapper;
    in
    rec {
      legacyPackages = forAllSystems (
        system:
        import ./. {
          inherit system;
        }
      );
      formatter = forAllSystems (system: mkTreefmt legacyPackages.${system});
      nixConfig = {
        extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
        extra-trusted-public-keys = [
          "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
        ];
      };
    };
}
