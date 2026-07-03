# Tmpfiles module infrastructure — parallel to service-module.nix
# Provides unified tmpfiles definitions across service managers
{ lib, pkgs }:

let
  inherit (lib) types mkOption;

  tmpfilesOpts = import ./tmpfiles-options.nix { inherit lib; };
  systemdTranslate = import ./tmpfiles-systemd-translate.nix { inherit lib pkgs; };
  shellTranslate = import ./tmpfiles-shell-translate.nix { inherit lib pkgs; };

in
{
  # Create a tmpfiles.rules module option
  mkTmpfilesOption = mkOption {
    default = [ ];
    type = types.listOf (types.submodule tmpfilesOpts.ruleOptions);
    description = "List of declarative file/directory state rules.";
  };

  # Generate systemd tmpfiles.d config
  mkSystemdTmpfiles =
    name: rules: systemdTranslate.toTmpfilesConfFile name rules;

  # Generate shell script (for runit, launchd, rcd)
  mkShellTmpfiles = name: rules: shellTranslate.toShellScript name rules;

  # Get shell commands as text (for embedding)
  mkShellTmpfilesText = rules: shellTranslate.toShellCommands rules;

  inherit systemdTranslate shellTranslate;
}
