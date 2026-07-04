# Translate structured tmpfiles rules to systemd tmpfiles.d format
{ lib, pkgs }:

let
  inherit (lib) concatStringsSep;

  # Convert a structured rule to a tmpfiles.d line
  ruleToTmpfilesLine =
    rule:
    let
      typeChar =
        {
          directory = "d";
          file = "f";
          symlink = "L";
          remove = "r";
          recursive-permissions = "Z";
        }
        .${rule.type};
      age = if rule.age != null then rule.age else "-";
      argument =
        if rule.type == "symlink" then
          rule.target or "-"
        else if rule.type == "file" && rule.content != null then
          rule.content
        else
          "-";
    in
    "${typeChar} ${rule.path} ${rule.mode} ${rule.user} ${rule.group} ${age} ${argument}";

in
{
  # Generate tmpfiles.d config file content
  toTmpfilesConf = rules: concatStringsSep "\n" (map ruleToTmpfilesLine rules);

  # Generate tmpfiles.d config as a derivation
  toTmpfilesConfFile =
    name: rules:
    pkgs.writeText "${name}-tmpfiles.conf" (concatStringsSep "\n" (map ruleToTmpfilesLine rules));
}
