# files — generate config files in the project directory
#
# Usage:
#   files."config.json".json = { key = "value"; };
#   files.".prettierrc".text = ''{ "semi": false }'';
#   files."setup.cfg".ini = { metadata = { name = "myproject"; }; };
{ lib, ... }:

let
  fileSubmodule = {
    options = {
      text = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Text content for the file.";
      };

      json = lib.mkOption {
        type = lib.types.nullOr lib.types.anything;
        default = null;
        description = "JSON value to serialize into the file.";
      };

      toml = lib.mkOption {
        type = lib.types.nullOr lib.types.anything;
        default = null;
        description = "TOML value to serialize into the file.";
      };

      executable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the file should be executable.";
      };
    };
  };
in
{
  options.files = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule fileSubmodule);
    default = { };
    description = "Files to generate in the project directory when entering the dev shell.";
  };
}
