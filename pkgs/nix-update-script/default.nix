{
  lib,
  nix,
  writeShellScript,
  common-updater-scripts,
  coreutils,
  curl,
  gnugrep,
  gnused,
  jq,
}:

{
  extraArgs ? [ ],
  attrPath ? null,
}:

let
  updateScript = writeShellScript "nix-update-script" ''
    set -euo pipefail

    attr_path="''${1:-$UPDATE_NIX_ATTR_PATH}"
    old_version="$UPDATE_NIX_OLD_VERSION"

    ${lib.getExe' common-updater-scripts "update-source-version"} \
      "$attr_path" \
      ${lib.concatStringsSep " " (map lib.escapeShellArg extraArgs)}
  '';
in
[
  updateScript
]
++ lib.optionals (attrPath != null) [ attrPath ]
