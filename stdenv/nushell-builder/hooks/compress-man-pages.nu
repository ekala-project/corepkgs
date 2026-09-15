# Compress man pages — nushell equivalent of setup-hooks/compress-man-pages.sh

export def compressManPages [] {
  let attrs = $env.__attrs
  if (($attrs | get -o dontGzipMan | default false) == true) { return }

  let prefix = $env.prefix
  let manDir = $"($prefix)/share/man"

  if not ($manDir | path exists) { return }

  # Find and gzip uncompressed man pages
  let files = (do { ^find $manDir -type f -not -name "*.gz" -not -name "*.bz2" -not -name "*.xz" } | complete | get stdout)

  $files | lines | where {|f| $f != ""} | each {|f|
    try { ^gzip -9nf $f } catch { }
  }

  # Fix symlinks pointing to uncompressed files
  let links = (do { ^find $manDir -type l } | complete | get stdout)

  $links | lines | where {|l| $l != ""} | each {|link|
    let target = (do { ^readlink $link } | complete | get stdout | str trim)
    if not ($target | str ends-with ".gz") {
      # Remove old symlink and create new one pointing to .gz version
      ^rm $link
      ^ln -s $"($target).gz" $"($link).gz"
    }
  }
  null
}
