# Move sbin — nushell equivalent of setup-hooks/move-sbin.sh
#
# Consolidates sbin/ into bin/ with a symlink.

export def moveSbin [] {
  let attrs = $env.__attrs
  if (($attrs | get -o dontMoveSbin | default false) == true) { return }

  let prefix = $env.prefix
  let sbin = $"($prefix)/sbin"

  if not ($sbin | path exists) { return }
  if ($sbin | path type) == "symlink" { return }

  let bin = $"($prefix)/bin"
  mkdir $bin

  ^cp -rn $"($sbin)/." $bin
  ^rm -rf $sbin
  ^ln -s bin $sbin
}
