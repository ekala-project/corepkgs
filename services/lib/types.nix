# Extended types for service definitions
{ lib }:

let
  inherit (lib) types mkOption;
in
{
  # A restart policy type
  restartPolicy = types.enum [
    "always"
    "on-failure"
    "on-abnormal"
    "on-abort"
    "on-watchdog"
    "never"
  ];

  # A command that can be either a string path or a derivation
  command = types.either types.path types.str;

  # Environment values (strings, paths, or packages)
  envValue = types.oneOf [
    types.str
    types.path
    types.package
  ];
}
