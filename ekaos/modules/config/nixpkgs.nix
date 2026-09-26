# Adios port of ekaos/modules/config/nixpkgs.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    config = {
      type = types.attrsOf types.any;
      default = { };
      example = {
        allowUnfree = true;
        allowBroken = false;
      };
      description = ''
        Configuration for the Nix package set.

        Common options:
        - allowUnfree: Allow packages with unfree licenses
        - allowBroken: Allow packages marked as broken
        - allowInsecure: Allow packages with known vulnerabilities
        - permittedInsecurePackages: List of specific insecure packages to allow
      '';
    };

    overlays = {
      type = types.listOf types.any;
      default = [ ];
      description = ''
        List of overlays to apply to the package set.

        Note: When using the ekaos system builder, overlays should
        be applied when importing the package set, not via this option.
        This option is provided for compatibility.
      '';
    };
  };

  assertions = [
    {
      # TODO(adios-cutover): the legacy assertion compared
      # options.nixpkgs.config.allowUnfree against pkgs.config.allowUnfree
      # at eval time. An adios verify function cannot read pkgs, so this
      # approximation fails closed on allowUnfree=true: align the pkgs
      # import instead (see message) and relax this assertion.
      verify = { options }: !(options.config.allowUnfree or false);
      explain =
        { options }:
        "nixpkgs.config.allowUnfree is set to ${toString options.config.allowUnfree} but the adios check cannot see the pkgs import config. "
        + "Pass the config when importing the package set (pkgs = import <core-pkgs> { config.allowUnfree = true; }) "
        + "and relax this assertion.";
    }
  ];

  impl = { ... }: { };
}
