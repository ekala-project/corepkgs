{
  description = "Core packages flake";

  inputs = {
    # For bootstrapping
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      # Helper function to generate outputs for each system
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fmt = treefmt-nix.lib.evalModule pkgs {
            programs.nixfmt.enable = true;
          };
        in
        fmt.config.build.wrapper
      );
    };
}
