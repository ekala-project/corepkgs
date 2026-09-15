# Multiple outputs — nushell equivalent of setup-hooks/multiple-outputs.sh
#
# Routes files to appropriate outputs (dev, lib, bin, man, etc.)

export def multiOutputSetup [] {
  let outputs = ($env.__attrs.outputs | columns)

  # Set up output variable defaults
  # dev output: includes, pkgconfig, cmake configs
  let outputDev = if "dev" in $outputs { "dev" } else { "out" }
  let outputBin = if "bin" in $outputs { "bin" } else { "out" }
  let outputLib = if "lib" in $outputs { "lib" } else { "out" }
  let outputDoc = if "doc" in $outputs { "doc" } else if "out" in $outputs { "out" } else { "out" }
  let outputMan = if "man" in $outputs { "man" } else { $outputDoc }
  let outputInfo = if "info" in $outputs { "info" } else { $outputDoc }
  let outputInclude = if "include" in $outputs { "include" } else { $outputDev }

  load-env {
    outputDev: $outputDev
    outputBin: $outputBin
    outputLib: $outputLib
    outputDoc: $outputDoc
    outputMan: $outputMan
    outputInfo: $outputInfo
    outputInclude: $outputInclude
  }
}

# Move files matching a pattern from one output to another
export def moveToOutput [pattern: string, targetOutput: string] {
  let src = $env.out
  let dest = (getOutputPath $targetOutput)

  if $src == $dest { return }

  let files = (glob $"($src)/($pattern)")
  for file in $files {
    let rel = ($file | str replace $src "")
    let destFile = $"($dest)($rel)"
    let destDir = ($destFile | path dirname)
    mkdir $destDir
    ^mv $file $destFile
  }
}

def getOutputPath [name: string]: nothing -> string {
  $env.__attrs.outputs | get $name
}
