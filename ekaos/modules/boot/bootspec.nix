# Adios port of ekaos/modules/boot/bootspec.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enableValidation = {
      type = types.bool;
      default = false;
      description = ''
        Whether to validate bootspec documents for each build.

        This introduces additional build-time dependencies for
        schema validation. Enable if you want to ensure your
        boot.json documents are correct.
      '';
    };

    extensions = {
      type = types.attrsOf types.any;
      default = { };
      example = {
        "org.example.custom" = {
          myOption = "value";
        };
      };
      description = ''
        User-defined data that extends the bootspec document.

        To reduce incompatibility and prevent name clashes
        between applications, use a unique namespace for your
        extensions (e.g. reverse domain notation).
      '';
    };
  };

  # Legacy defines no config section (generation is handled by
  # system/toplevel.nix); impl is empty.
  impl = { ... }: { };
}
