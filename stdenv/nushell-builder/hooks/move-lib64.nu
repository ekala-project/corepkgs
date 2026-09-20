# Move lib64 — nushell equivalent of setup-hooks/move-lib64.sh
#
# Consolidates lib64/ into lib/ with a symlink. Different bitnesses get
# separate store paths in Nix, so lib64 is unnecessary.

export def moveLib64 [] {
  let attrs = $env.__attrs
  if (($attrs | get -o dontMoveLib64 | default false) == true) { return }

  let prefix = $env.prefix
  let lib64 = $"($prefix)/lib64"

  if not ($lib64 | path exists) { return }
  if ($lib64 | path type) == "symlink" { return }

  let lib = $"($prefix)/lib"
  mkdir $lib

  ^cp -rn $"($lib64)/." $lib
  ^rm -rf $lib64
  ^ln -s lib $lib64
}
