# Strip binaries and libraries — nushell equivalent of setup-hooks/strip.sh

export def doStrip [outputPath: string] {
  let attrs = $env.__attrs

  if (($attrs | get -o dontStrip | default false) == true) { return }

  let strip = ($env | get -o STRIP | default "strip")
  let ranlib = ($env | get -o RANLIB | default "ranlib")
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")

  let stripDebugFlags = ($attrs | get -o stripDebugFlags | default ["-S" "-p"])
  let stripAllFlags = ($attrs | get -o stripAllFlags | default ["-s" "-p"])

  # Directories to strip debug info from (libraries)
  let stripDebugDirs = ($attrs | get -o stripDebugList | default ["lib" "lib32" "lib64" "libexec" "bin" "sbin"])
  # Directories to fully strip (executables)
  let stripAllDirs = ($attrs | get -o stripAllList | default [])

  # Strip debug info from libraries
  for dir in $stripDebugDirs {
    let fullDir = $"($outputPath)/($dir)"
    if ($fullDir | path exists) {
      stripDir $fullDir $strip $stripDebugFlags $cores
    }
  }

  # Fully strip executables
  for dir in $stripAllDirs {
    let fullDir = $"($outputPath)/($dir)"
    if ($fullDir | path exists) {
      stripDir $fullDir $strip $stripAllFlags $cores
    }
  }

  # Restore archive indexes
  let libDir = $"($outputPath)/lib"
  if ($libDir | path exists) {
    glob $"($libDir)/**/*.a" | each {|f|
      do { ^$ranlib $f } | complete | ignore
    }
  }
}

def stripDir [dir: string, strip: string, flags: list<string>, cores: string] {
  # Find ELF files and strip them
  let files = (do {
    ^find $dir -type f -not -path "*/lib/debug/*" -print0
  } | complete | get stdout)

  if ($files | str trim) == "" { return }

  # Process files
  $files | split row "\u{0}" | where {|f| $f != ""} | each {|f|
    # Check if file is ELF by reading magic bytes
    let isElf = try {
      let bytes = (open $f --raw | bytes at 0..4)
      ($bytes | encode hex) == "7f454c46"  # \x7fELF
    } catch { false }
    if $isElf {
      try { ^$strip ...$flags $f } catch { }
    }
  }
  null
}
