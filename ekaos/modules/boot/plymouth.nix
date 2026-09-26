# Adios port of ekaos/modules/boot/plymouth.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the Plymouth boot splash screen.

        Plymouth provides a graphical boot animation that hides
        the text-mode boot messages.
      '';
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.plymouth or null;
      description = "The Plymouth package to use.";
    };

    theme = {
      type = types.string;
      default = "bgrt";
      example = "spinner";
      description = ''
        Plymouth splash screen theme name.
      '';
    };

    themePackages = {
      type = types.listOf types.derivation;
      default = [ ];
      description = "Extra theme packages for Plymouth.";
    };

    logo = {
      type = types.nullOr types.pathLike;
      default = null;
      description = ''
        Logo displayed on the splash screen (PNG format).
      '';
    };

    font = {
      type = types.nullOr types.pathLike;
      default = null;
      description = "Font file for displaying text on the splash screen.";
    };

    showDelay = {
      type = types.int;
      default = 0;
      example = 1;
      description = "Time (in seconds) to delay the splash screen.";
    };

    extraConfig = {
      type = types.string;
      default = "";
      description = "Additional configuration lines for plymouthd.conf.";
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain =
        { options, ... }: "package option must be set when enabled (plymouth is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        boot.kernelParams = [ "splash" ];

        environment.systemPackages = [ options.package ] ++ options.themePackages;

        environment.etc."plymouth/plymouthd.conf".text = ''
          [Daemon]
          Theme=${options.theme}
          ShowDelay=${toString options.showDelay}
          ${if options.logo != null then "Logo=${options.logo}" else ""}
          ${options.extraConfig}
        '';

        # TODO(adios-cutover): stringAfter [ "etc" ] ordering dropped.
        system.activationScripts.plymouth = ''
          mkdir -p /var/lib/plymouth
          mkdir -p /var/log
          mkdir -p /run/plymouth
        '';
      };
}
