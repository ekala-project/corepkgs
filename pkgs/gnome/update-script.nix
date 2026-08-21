{
  lib,
  writeShellScript,
  common-updater-scripts,
  coreutils,
  curl,
  gnugrep,
  gnused,
  jq,
  nix,
}:

{
  packageName,
  attrPath ? null,
  versionPolicy ? null,
  freeze ? false,
}:

let
  grep = lib.getExe gnugrep;
  sed = lib.getExe gnused;

  updateScript = writeShellScript "gnome-update-script" ''
    set -euo pipefail

    package_name="$1"
    attr_path="''${2:-$package_name}"
    old_version="$UPDATE_NIX_OLD_VERSION"

    # Fetch version info from GNOME's cache.json
    cache=$(${lib.getExe curl} -s "https://download.gnome.org/sources/$package_name/cache.json")
    if [ -z "$cache" ]; then
      echo "Failed to fetch version info for $package_name" >&2
      exit 1
    fi

    # Extract latest stable version
    latest=$(echo "$cache" | ${lib.getExe jq} -r '.[0]."$package_name"? // empty | keys[]' 2>/dev/null | \
      ${grep} -E '^[0-9]+\.[0-9]+' | \
      ${sed} '/alpha\|beta\|rc/d' | \
      ${lib.getExe' coreutils "sort"} --version-sort | \
      tail -1)

    if [ -z "$latest" ]; then
      # Fallback: try array format
      latest=$(echo "$cache" | ${lib.getExe jq} -r '.[2]."$package_name"? // empty | .[]' 2>/dev/null | \
        ${grep} -E '^[0-9]+\.[0-9]+' | \
        ${sed} '/alpha\|beta\|rc/d' | \
        ${lib.getExe' coreutils "sort"} --version-sort | \
        tail -1)
    fi

    ${lib.optionalString (versionPolicy == "odd-unstable") ''
      # Filter out odd minor versions (development releases)
      latest=$(echo "$cache" | ${lib.getExe jq} -r '.[2]."'"$package_name"'"? // empty | .[]' 2>/dev/null | \
        ${grep} -E '^[0-9]+\.[0-9]+' | \
        ${sed} '/alpha\|beta\|rc/d' | \
        while IFS= read -r v; do
          minor=$(echo "$v" | ${sed} -rne 's,^[0-9]+\.([0-9]+).*,\1,p')
          if [ $((minor % 2)) -eq 0 ]; then
            echo "$v"
          fi
        done | \
        ${lib.getExe' coreutils "sort"} --version-sort | \
        tail -1)
    ''}

    if [ -z "$latest" ] || [ "$latest" = "$old_version" ]; then
      exit 0
    fi

    ${lib.getExe' common-updater-scripts "update-source-version"} \
      "$attr_path" "$latest"
  '';
in
[
  updateScript
  packageName
  (if attrPath != null then attrPath else packageName)
]
