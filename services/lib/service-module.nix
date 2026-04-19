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
  runitOpts = import ./runit-options.nix { inherit lib; };
  runitTranslate = import ./runit-translate.nix { inherit lib pkgs; };
  rcdOpts = import ./rcd-options.nix { inherit lib; };
  rcdTranslate = import ./rcd-translate.nix { inherit lib pkgs; };

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

        runit = mkOption {
          type = types.submodule (runitOpts.runitOptions { inherit name config; });
          default = { };
          description = "Runit-specific options";
        };

        rcd = mkOption {
          type = types.submodule (rcdOpts.rcdOptions { inherit name config; });
          default = { };
          description = "BSD rc.d-specific options";
        };
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

  # Generate runit service directories from service definitions
  mkRunitServices =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      runitTranslate.toRunitService name config
    ) enabledServices;

  # Generate BSD rc.d service files (FreeBSD/NetBSD/DragonFly)
  mkRcdServices =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      let
        variant = config.rcd.variant or "freebsd";
      in
      rcdTranslate.toRcdService variant name config
    ) enabledServices;

  # Generate BSD rc.d service files (OpenBSD variant)
  mkRcdServicesOpenBSD =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
    in
    mapAttrs (
      name: config:
      rcdTranslate.toRcdService "openbsd" name config
    ) enabledServices;

  inherit systemdTranslate launchdTranslate runitTranslate rcdTranslate;
}
