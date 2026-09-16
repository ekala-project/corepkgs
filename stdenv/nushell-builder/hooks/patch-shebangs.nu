# Patch shebangs — nushell equivalent of setup-hooks/patch-shebangs.sh
#
# Rewrites #! interpreter paths in scripts to absolute store paths.

export def patchShebangsAuto [outputPath: string] {
  let attrs = $env.__attrs
  if (($attrs | get -o dontPatchShebangs | default false) == true) { return }

  patchShebangs $outputPath
}

export def patchShebangs [dir: string] {
  if not ($dir | path exists) { return }

  let path = ($env | get -o PATH | default "")
  let hostPath = ($env | get -o HOST_PATH | default "")

  # Find all regular executable files
  let files = (do { ^find $dir -type f -executable -print0 } | complete | get stdout)
  if ($files | str trim) == "" { return }

  $files | split row "\u{0}" | where {|f| $f != ""} | each {|f|
    patchShebang $f $path $hostPath
  }
  null
}

def patchShebang [file: string, path: string, hostPath: string] {
  # Read first line and check for shebang
  let firstLine = try { open $file --raw | lines | first } catch { return }
  if not ($firstLine | str starts-with "#!") { return }

  let shebang = ($firstLine | str substring 2.. | str trim)
  if $shebang == "" { return }

  # Parse the shebang
  let parts = ($shebang | split row " " | where {|p| $p != ""})
  let interpreter = ($parts | first)
  let rest = ($parts | skip 1)

  # Skip if already a store path
  let nixStore = ($env | get -o NIX_STORE | default "/nix/store")
  if ($interpreter | str starts-with $nixStore) { return }

  # Handle /usr/bin/env
  mut newInterpreter = ""
  if $interpreter == "/usr/bin/env" and ($rest | length) > 0 {
    let cmd = ($rest | first)
    $newInterpreter = (findOnPath $cmd $path $hostPath)
    if $newInterpreter == "" { return }
    # Rewrite to direct interpreter path
    let newShebang = $"#!($newInterpreter) ($rest | skip 1 | str join ' ')" | str trim
    rewriteShebang $file $firstLine $newShebang
  } else {
    # Direct interpreter path
    let cmd = ($interpreter | path basename)
    $newInterpreter = (findOnPath $cmd $path $hostPath)
    if $newInterpreter == "" { return }
    let newShebang = $"#!($newInterpreter) ($rest | str join ' ')" | str trim
    rewriteShebang $file $firstLine $newShebang
  }
}

def findOnPath [cmd: string, path: string, hostPath: string]: nothing -> string {
  # Search PATH first, then HOST_PATH
  for searchPath in [$path $hostPath] {
    if $searchPath == "" { continue }
    for dir in ($searchPath | split row ":") {
      let candidate = $"($dir)/($cmd)"
      if ($candidate | path exists) {
        return $candidate
      }
    }
  }
  ""
}

def rewriteShebang [file: string, oldLine: string, newLine: string] {
  if $oldLine == $newLine { return }
  print -e $"patching shebang of ($file): ($oldLine) -> ($newLine)"

  let content = (open $file --raw)
  let newContent = ($content | str replace $oldLine $newLine)
  $newContent | save -f $file
}
