# Move docs — nushell equivalent of setup-hooks/move-docs.sh
#
# Moves $prefix/{man,doc,info} to $prefix/share/{man,doc,info}

export def moveDocs [] {
  let prefix = $env.prefix
  let forceShare = ($env.__attrs | get -o forceShare | default ["man" "doc" "info"])

  for dir in $forceShare {
    let src = $"($prefix)/($dir)"
    let dest = $"($prefix)/share/($dir)"

    if ($src | path exists) and ($src | path type) == "dir" {
      mkdir ($dest | path dirname)
      if ($dest | path exists) {
        # Merge into existing directory
        ^cp -rn $"($src)/." $dest
        ^rm -rf $src
      } else {
        ^mv $src $dest
      }
    }
  }
}
