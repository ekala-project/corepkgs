# Core service module infrastructure
{ lib, pkgs }:

let
  inherit (lib)
    types
    mkOption
    mapAttrs
    filterAttrs
    nameValuePair
    ;

  commonOpts = import ./options.nix { inherit lib; };
  systemdOpts = import ./systemd-options.nix { inherit lib; };
  systemdTranslate = import ./systemd-translate.nix { inherit lib pkgs; };

  # Service option type
  serviceOpts =
    { name, config, ... }:
    {
      options = commonOpts.commonOptions // {
        # Service name (automatically set)
        name = mkOption {
          type = types.str;
          default = name;
          description = "Service name";
        };

        # Manager-specific options
        systemd = mkOption {
          type = types.submodule { options = systemdOpts.systemdOptions; };
          default = { };
          description = "Systemd-specific options";
        };

        # TODO: Add launchd, runit, rcd options
      };
    };

in
{
  # Create a services.* module option
  mkServicesOption = mkOption {
    default = { };
    type = types.attrsOf (types.submodule serviceOpts);
    description = "Attribute set of services";
  };

  # Generate systemd user service files from service definitions
  mkSystemdUserServices =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      let
        unitText = systemdTranslate.toSystemdUnit config;
      in
      pkgs.writeTextFile {
        name = "${name}.service";
        text = unitText;
        destination = "/${name}.service";
      }
    ) enabledServices;

  inherit systemdTranslate;
}
