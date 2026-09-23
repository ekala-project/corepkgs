# enterShell — bash code to run when entering the dev shell
#
# Usage:
#   enterShell = ''
#     echo "Welcome to the project!"
#     export MY_VAR=foo
#   '';
{ lib, ... }:

{
  options.enterShell = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Bash code to execute when entering the dev shell.";
  };
}
