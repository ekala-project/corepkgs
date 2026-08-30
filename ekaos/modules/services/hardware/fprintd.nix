# Fingerprint authentication daemon
# Ported from nixpkgs/nixos/modules/services/security/fprintd.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.fprintd;
  fprintdPkg = if cfg.tod.enable then pkgs.fprintd-tod else cfg.package;
in
{
  options.services.fprintd = {
    enable = lib.mkEnableOption "fprintd daemon for fingerprint reader support";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fprintd or (throw "fprintd package not available");
      defaultText = lib.literalExpression "pkgs.fprintd";
      description = "The fprintd package to use.";
    };

    tod = {
      enable = lib.mkEnableOption "Touch OEM Drivers library support";

      driver = lib.mkOption {
        type = lib.types.package;
        example = lib.literalExpression "pkgs.libfprint-2-tod1-goodix";
        description = "Touch OEM Drivers (TOD) package to use.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.dbus.packages = [ fprintdPkg ];
    environment.systemPackages = [ fprintdPkg ];

    # TODO: systemd.packages not yet available in ekaOS
    # systemd.packages = [ fprintdPkg ];
  };
}
