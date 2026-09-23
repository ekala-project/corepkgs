# env — environment variables for the dev shell
#
# Usage:
#   env.DATABASE_URL = "postgres://localhost/mydb";
#   env.RUST_LOG = "debug";
{ lib, ... }:

{
  options.env = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Environment variables to set in the dev shell.";
    example = {
      DATABASE_URL = "postgres://localhost/mydb";
    };
  };
}
