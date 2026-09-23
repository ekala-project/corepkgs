# scripts — define named shell scripts available in the dev shell
#
# Usage:
#   scripts.hello = "echo hello world";
#   scripts.build = "cargo build --release";
{ lib, ... }:

{
  options.scripts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Named shell scripts to make available in the dev shell.";
    example = {
      build = "cargo build --release";
      test = "cargo test";
    };
  };
}
