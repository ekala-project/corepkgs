# Bootspec (RFC-0125) configuration
# Controls boot.json generation for systemd-boot and other consumers
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    boot.bootspec = {
      enableValidation = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to validate bootspec documents for each build.

          This introduces additional build-time dependencies for
          schema validation. Enable if you want to ensure your
          boot.json documents are correct.
        '';
      };

      extensions = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = literalExpression ''
          {
            "org.example.custom" = {
              myOption = "value";
            };
          }
        '';
        description = ''
          User-defined data that extends the bootspec document.

          To reduce incompatibility and prevent name clashes
          between applications, use a unique namespace for your
          extensions (e.g. reverse domain notation).
        '';
      };
    };
  };

  # Bootspec generation is handled by system/toplevel.nix
}
