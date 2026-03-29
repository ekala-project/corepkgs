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
  launchdOpts = import ./launchd-options.nix { inherit lib; };
  launchdTranslate = import ./launchd-translate.nix { inherit lib pkgs; };

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

        launchd = mkOption {
          type = types.submodule (launchdOpts.launchdOptions { inherit name config; });
          default = { };
          description = "Launchd-specific options (macOS)";
        };

        # TODO: Add runit, rcd options
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
        unitText = systemdTranslate.toSystemdUnit { serviceType = "user"; } config;
      in
      pkgs.writeTextFile {
        name = "${name}.service";
        text = unitText;
        destination = "/${name}.service";
      }
    ) enabledServices;

  # Generate systemd system service files from service definitions
  mkSystemdSystemServices =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      let
        unitText = systemdTranslate.toSystemdUnit { serviceType = "system"; } config;
      in
      pkgs.writeTextFile {
        name = "${name}.service";
        text = unitText;
        destination = "/${name}.service";
      }
    ) enabledServices;

  # Generate launchd user agent plist files from service definitions
  mkLaunchdUserAgents =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      let
        plistResult = launchdTranslate.toLaunchdPlist config;
        plistContent = plistResult.plistContent;
      in
      pkgs.writeTextFile {
        name = "${name}.plist";
        text = plistContent;
        destination = "/${name}.plist";
      }
    ) enabledServices;

  # Generate launchd daemon plist files (system-wide) from service definitions
  mkLaunchdDaemons =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      let
        plistResult = launchdTranslate.toLaunchdPlist config;
        plistContent = plistResult.plistContent;
      in
      pkgs.writeTextFile {
        name = "${name}.plist";
        text = plistContent;
        destination = "/${name}.plist";
      }
    ) enabledServices;

  inherit systemdTranslate launchdTranslate;
}
