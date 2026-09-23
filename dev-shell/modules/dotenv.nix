# dotenv — load .env files into the shell environment
#
# Usage:
#   dotenv.enable = true;
#   dotenv.filename = ".env";  # or a list: [ ".env" ".env.local" ]
{ lib, ... }:

{
  options.dotenv = {
    enable = lib.mkEnableOption "loading .env files into the shell environment";

    filename = lib.mkOption {
      type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
      default = ".env";
      description = "Path to .env file(s) to load, relative to the project root.";
    };
  };
}
