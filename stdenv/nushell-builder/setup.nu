# mkEkaPackage nushell builder — replaces source-stdenv.sh + setup.sh + default-builder.sh
#
# Entry point for all mkEkaPackage derivations. Reads structured attrs from
# $NIX_ATTRS_JSON_FILE, sets up the build environment, activates dependencies,
# detects nushell hooks from nativeBuildInputs, and runs the standard phase
# sequence.

use hooks/strip.nu
use hooks/patch-shebangs.nu
use hooks/multiple-outputs.nu
use hooks/compress-man-pages.nu
use hooks/move-docs.nu
use hooks/move-lib64.nu
use hooks/move-sbin.nu
use hooks/propagated-deps.nu

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Log a phase start in Nix structured-log format
def note [kind: string, msg: string = ""] {
  let ev = if $kind == "phase" {
    {action: setPhase, phase: $msg}
  } else {
    {action: msg, level: 3, msg: $"($kind): ($msg)"}
  }
  print -e $"@nix ($ev | to json -r)"
}

# Run all hooks in a named hook array (e.g. __preConfigureHooks).
# Hook arrays are stored as lists of closures in $env.
def --env runHook [name: string] {
  let hookVar = $"__($name)Hooks"
  let hooks = ($env | get -o $hookVar | default [])
  for hook in $hooks {
    do $hook
  }
}

# Add a path to a colon-separated env var if the path exists
def --env addToSearchPath [varName: string, dir: string] {
  if ($dir | path exists) {
    let current = ($env | get -o $varName | default "")
    if $current == "" {
      load-env {$varName: $dir}
    } else {
      load-env {$varName: $"($current):($dir)"}
    }
  }
}

# Get all output names from the attrs
def getAllOutputNames [] {
  $env.__attrs.outputs | columns
}

# Get the store path for a given output name
def getOutput [name: string] {
  $env.__attrs.outputs | get $name
}

# Get an attribute from attrs with a default
def attr [name: string, default: any = null] {
  $env.__attrs | get -o $name | default $default
}

# Check if a flag attribute is truthy
def attrBool [name: string, default: bool = false] {
  let val = (attr $name)
  if $val == null {
    $default
  } else if ($val | describe) == "bool" {
    $val
  } else if ($val | describe) == "int" {
    $val != 0
  } else if ($val | describe) == "string" {
    $val != "" and $val != "0"
  } else {
    $default
  }
}

# Evaluate a nushell code string (for inline phase overrides)
def --env evalNu [code: string] {
  let nuBin = ($nu.current-exe)
  ^$nuBin --no-config-file -c $code
}

# Execute an external command with logging
def --env x [cmd: string, ...args: string] {
  print -e $"+ ($cmd) ($args | str join ' ')"
  ^$cmd ...$args
}

# ---------------------------------------------------------------------------
# Environment setup
# ---------------------------------------------------------------------------

def --env setupEnvironment [] {
  let attrs = $env.__attrs

  # Export outputs as env vars
  for col in ($attrs.outputs | columns) {
    load-env {$col: ($attrs.outputs | get $col)}
  }

  # Set prefix to primary output
  load-env {prefix: $env.out}

  # Reproducibility
  load-env {
    SOURCE_DATE_EPOCH: "315532800"
    TZ: "UTC"
    LC_ALL: "C.UTF-8"
    ZERO_AR_DATE: "1"
    PERL_HASH_SEED: "0"
    PYTHONHASHSEED: "0"
    KBUILD_BUILD_TIMESTAMP: "@315532800"
    KBUILD_BUILD_USER: "nixbld"
    KBUILD_BUILD_HOST: "localhost"
  }

  # Writable HOME
  let home = $"($env.NIX_BUILD_TOP)/homeless-shelter"
  mkdir $home
  load-env {
    HOME: $home
    XDG_CACHE_HOME: $"($home)/.cache"
    XDG_DATA_HOME: $"($home)/.local/share"
    XDG_CONFIG_HOME: $"($home)/.config"
    TMPDIR: $env.NIX_BUILD_TOP
  }

  # NIX_BUILD_CORES
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")
  let coresInt = if ($cores | into int) <= 0 {
    try { ^nproc | str trim | into int } catch { 1 }
  } else {
    $cores | into int
  }
  load-env {NIX_BUILD_CORES: ($coresInt | into string)}

  # User-specified env attributes
  let userEnv = ($attrs | get -o env | default {})
  if ($userEnv | describe) == "record" and ($userEnv | columns | length) > 0 {
    # Convert all values to strings for the environment
    let envRecord = ($userEnv | items {|k, v|
      {$k: (if ($v | describe) == "bool" {
        if $v { "1" } else { "" }
      } else {
        $v | into string
      })}
    } | reduce -f {} {|it, acc| $acc | merge $it})
    load-env $envRecord
  }

  # Initial PATH from stdenv (coreutils, findutils, etc.)
  # Parse the initialPath from the stdenv setup file
  let stdenvPath = (attr stdenv)
  if $stdenvPath != null {
    let setupFile = $"($stdenvPath)/setup"
    if ($setupFile | path exists) {
      let setupContent = (open --raw $setupFile)
      let initialPathLine = (try { $setupContent | lines | where {|l| $l | str starts-with "initialPath="} | first } catch { null })
      if $initialPathLine != null {
        let initialPath = ($initialPathLine | str replace 'initialPath="' '' | str replace '"' '' | str trim)
        let pathEntries = ($initialPath | split row " " | each {|p| $"($p)/bin"} | where {|p| $p | path exists})
        let existingPath = ($env | get -o PATH | default "")
        let newPath = if $existingPath != "" {
          $"($existingPath):($pathEntries | str join ':')"
        } else {
          ($pathEntries | str join ":")
        }
        load-env {PATH: $newPath}
      }
    }
  }

  # SSL certificates
  let certFile = ($env | get -o NIX_SSL_CERT_FILE | default "")
  if $certFile != "" {
    load-env {
      SSL_CERT_FILE: $certFile
      GIT_SSL_CAINFO: $certFile
      CURL_CA_BUNDLE: $certFile
    }
  }
}

# ---------------------------------------------------------------------------
# Dependency activation
# ---------------------------------------------------------------------------

def --env activateDependencies [] {
  let attrs = $env.__attrs
  let strictDeps = (attrBool strictDeps true)

  # Initialize hook arrays
  load-env {
    __preUnpackHooks: []
    __postUnpackHooks: []
    __prePatchHooks: []
    __postPatchHooks: []
    __preConfigureHooks: []
    __postConfigureHooks: []
    __preBuildHooks: []
    __postBuildHooks: []
    __preCheckHooks: []
    __postCheckHooks: []
    __preInstallHooks: []
    __postInstallHooks: []
    __preFixupHooks: []
    __postFixupHooks: []
    __fixupOutputHooks: []
    __preInstallCheckHooks: []
    __postInstallCheckHooks: []
  }

  # Build PATH from nativeBuildInputs (commands)
  let nativeBuildInputs = ($attrs | get -o nativeBuildInputs | default [])
  let buildInputs = ($attrs | get -o buildInputs | default [])
  let depsBuildBuild = ($attrs | get -o depsBuildBuild | default [])

  # nativeBuildInputs always go on PATH
  let pathDirs = ($nativeBuildInputs | each {|dep|
    let binDir = $"($dep)/bin"
    if ($binDir | path exists) { $binDir } else { null }
  } | compact)

  # depsBuildBuild also go on PATH
  let pathDirsBB = ($depsBuildBuild | each {|dep|
    let binDir = $"($dep)/bin"
    if ($binDir | path exists) { $binDir } else { null }
  } | compact)

  # buildInputs only go on PATH if not strictDeps
  let pathDirsBI = if not $strictDeps {
    $buildInputs | each {|dep|
      let binDir = $"($dep)/bin"
      if ($binDir | path exists) { $binDir } else { null }
    } | compact
  } else { [] }

  let allPathDirs = ($pathDirsBB ++ $pathDirs ++ $pathDirsBI)
  let existingPath = ($env | get -o PATH | default "")
  let newPath = if ($allPathDirs | length) > 0 {
    let joined = ($allPathDirs | str join ":")
    if $existingPath != "" { $"($joined):($existingPath)" } else { $joined }
  } else {
    $existingPath
  }
  load-env {PATH: $newPath}

  # Build HOST_PATH (for runtime shebang patching)
  let hostPathDirs = ($buildInputs | each {|dep|
    let binDir = $"($dep)/bin"
    if ($binDir | path exists) { $binDir } else { null }
  } | compact)
  if ($hostPathDirs | length) > 0 {
    load-env {HOST_PATH: ($hostPathDirs | str join ":")}
  }

  # Build search paths from all deps (both native and host)
  let allDeps = ($nativeBuildInputs ++ $buildInputs ++ $depsBuildBuild)

  for dep in $allDeps {
    addToSearchPath PKG_CONFIG_PATH $"($dep)/lib/pkgconfig"
    addToSearchPath PKG_CONFIG_PATH $"($dep)/share/pkgconfig"
    addToSearchPath CMAKE_PREFIX_PATH $dep
    addToSearchPath ACLOCAL_PATH $"($dep)/share/aclocal"
    addToSearchPath XDG_DATA_DIRS $"($dep)/share"
    addToSearchPath PERL5LIB $"($dep)/lib/perl5/site_perl"
  }

  # Also add propagated deps from all direct deps
  for dep in $allDeps {
    propagateSearchPaths $dep
  }

  # Collect nushell hook paths (.nu files in nativeBuildInputs)
  # These are paths like cmake.nushellHook that point to .nu files.
  # They will be executed during phases to override default behavior.
  let nuHooks = ($nativeBuildInputs | where {|dep|
    ($dep | str ends-with ".nu") and ($dep | path exists)
  })
  load-env {__nuHooks: $nuHooks}
}

# Walk a dependency's nix-support/ for propagated deps and add their paths
def --env propagateSearchPaths [dep: string] {
  let supportDir = $"($dep)/nix-support"
  if not ($supportDir | path exists) { return }

  # Read propagated deps and add their paths
  for file in ["propagated-native-build-inputs" "propagated-build-inputs"] {
    let filePath = $"($supportDir)/($file)"
    if ($filePath | path exists) {
      let deps = (open --raw $filePath | str trim | split row " " | where {|d| $d != ""})
      for pdep in $deps {
        if ($pdep | path exists) {
          addToSearchPath PKG_CONFIG_PATH $"($pdep)/lib/pkgconfig"
          addToSearchPath PKG_CONFIG_PATH $"($pdep)/share/pkgconfig"
          addToSearchPath CMAKE_PREFIX_PATH $pdep
          addToSearchPath XDG_DATA_DIRS $"($pdep)/share"
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Phase implementations
# ---------------------------------------------------------------------------

def --env unpackPhase [] {
  runHook preUnpack

  let src = (attr src)
  let srcs = (attr srcs [])
  let srcList = if ($srcs | length) > 0 { $srcs } else if $src != null { [$src] } else {
    print -e "error: variable src or srcs should point to the source"
    exit 1
  }

  # Record dirs before unpacking
  let dirsBefore = (ls | where type == dir | get name)

  # Unpack each source
  for s in $srcList {
    unpackFile $s
  }

  # Determine source root
  mut sourceRoot = (attr sourceRoot "")
  if $sourceRoot == "" {
    let dirsAfter = (ls | where type == dir | get name)
    let newDirs = ($dirsAfter | where {|d| $d not-in $dirsBefore})
    if ($newDirs | length) == 1 {
      $sourceRoot = ($newDirs | first)
    } else if ($newDirs | length) > 1 {
      print -e "unpacker produced multiple directories"
      exit 1
    } else {
      print -e "unpacker appears to have produced no directories"
      exit 1
    }
  }

  print -e $"source root is ($sourceRoot)"

  # Make sources writable
  if not (attrBool dontMakeSourcesWritable) {
    ^chmod -R u+w -- $sourceRoot
  }

  load-env {sourceRoot: $sourceRoot}

  runHook postUnpack

  # Change to source directory
  cd $env.sourceRoot
}

# Unpack a single source file
def unpackFile [file: string] {
  if ($file | path type) == "dir" {
    let base = ($file | path basename)
    ^cp -rT $file $base
  } else {
    let name = ($file | path basename)
    # Detect archive type and extract
    if ($name | str ends-with ".tar.gz") or ($name | str ends-with ".tgz") {
      ^tar xzf $file
    } else if ($name | str ends-with ".tar.bz2") or ($name | str ends-with ".tbz2") {
      ^tar xjf $file
    } else if ($name | str ends-with ".tar.xz") or ($name | str ends-with ".txz") {
      ^tar xJf $file
    } else if ($name | str ends-with ".tar.zst") or ($name | str ends-with ".tar.zstd") {
      ^tar --use-compress-program=unzstd -xf $file
    } else if ($name | str ends-with ".tar.lz") {
      ^tar --use-compress-program=lzip -xf $file
    } else if ($name | str ends-with ".tar") {
      ^tar xf $file
    } else if ($name | str ends-with ".zip") {
      ^unzip -qq $file
    } else {
      print -e $"don't know how to unpack ($file)"
      exit 1
    }
  }
}

def --env patchPhase [] {
  runHook prePatch

  let patches = (attr patches [])
  let patchFlags = (attr patchFlags ["-p1"])

  for p in $patches {
    print -e $"applying patch ($p)"
    let name = ($p | path basename)
    if ($name | str ends-with ".gz") {
      ^gzip -d -c $p | ^patch ...$patchFlags
    } else if ($name | str ends-with ".bz2") {
      ^bzip2 -d -c $p | ^patch ...$patchFlags
    } else if ($name | str ends-with ".xz") {
      ^xz -d -c $p | ^patch ...$patchFlags
    } else {
      ^patch ...$patchFlags -i $p
    }
  }

  runHook postPatch
}

def --env configurePhase [] {
  runHook preConfigure

  # Check for string override from attrs
  let phaseStr = (attr configurePhase)
  if $phaseStr != null and ($phaseStr | describe) == "string" {
    evalNu $phaseStr
    runHook postConfigure
    return
  }

  # Default: autotools-style configure
  let configureScript = (attr configureScript "./configure")
  if not ($configureScript | path exists) {
    print -e "no configure script, doing nothing"
    runHook postConfigure
    return
  }

  let configureFlags = (attr configureFlags [])
  let prefix = $env.out

  mut flags = []
  if not (attrBool dontAddPrefix) {
    $flags = ($flags | append $"--prefix=($prefix)")
  }
  $flags = ($flags | append $configureFlags)

  x $configureScript ...$flags

  runHook postConfigure
}

def --env buildPhase [] {
  runHook preBuild

  # Check for phase override
  let override = ($env | get -o __buildPhase)
  if $override != null {
    do $override
    runHook postBuild
    return
  }

  # Check for string override from attrs
  let phaseStr = (attr buildPhase)
  if $phaseStr != null and ($phaseStr | describe) == "string" {
    evalNu $phaseStr
    runHook postBuild
    return
  }

  # Default: make
  let hasMakefile = (("Makefile" | path exists) or ("makefile" | path exists) or ("GNUmakefile" | path exists))
  let makeFlags = (attr makeFlags [])

  if not $hasMakefile and ($makeFlags | length) == 0 {
    print -e "no Makefile or custom buildPhase, doing nothing"
    runHook postBuild
    return
  }

  let buildFlags = (attr buildFlags [])
  let cores = $env.NIX_BUILD_CORES
  let parallelFlag = if (attrBool enableParallelBuilding true) { [$"-j($cores)"] } else { [] }

  x make ...$parallelFlag ...$makeFlags ...$buildFlags

  runHook postBuild
}

def --env checkPhase [] {
  runHook preCheck

  # Check for phase override
  let override = ($env | get -o __checkPhase)
  if $override != null {
    do $override
    runHook postCheck
    return
  }

  # Check for string override from attrs
  let phaseStr = (attr checkPhase)
  if $phaseStr != null and ($phaseStr | describe) == "string" {
    evalNu $phaseStr
    runHook postCheck
    return
  }

  # Default: make check or make test
  let hasMakefile = (("Makefile" | path exists) or ("makefile" | path exists) or ("GNUmakefile" | path exists))
  if not $hasMakefile {
    print -e "no Makefile or custom checkPhase, doing nothing"
    runHook postCheck
    return
  }

  let checkTarget = (attr checkTarget)
  let target = if $checkTarget != null {
    $checkTarget
  } else if (do { ^make -n check out+err>| complete | get exit_code } == 0) {
    "check"
  } else if (do { ^make -n test out+err>| complete | get exit_code } == 0) {
    "test"
  } else {
    null
  }

  if $target == null {
    print -e "no check/test target in Makefile, doing nothing"
    runHook postCheck
    return
  }

  let checkFlags = (attr checkFlags [])
  let makeFlags = (attr makeFlags [])
  let cores = $env.NIX_BUILD_CORES
  let parallelFlag = if (attrBool enableParallelChecking true) { [$"-j($cores)"] } else { [] }

  x make $target ...$parallelFlag ...$makeFlags ...$checkFlags

  runHook postCheck
}

def --env installPhase [] {
  runHook preInstall

  # Check for phase override
  let override = ($env | get -o __installPhase)
  if $override != null {
    do $override
    runHook postInstall
    return
  }

  # Check for string override from attrs
  let phaseStr = (attr installPhase)
  if $phaseStr != null and ($phaseStr | describe) == "string" {
    evalNu $phaseStr
    runHook postInstall
    return
  }

  # Default: make install
  let hasMakefile = (("Makefile" | path exists) or ("makefile" | path exists) or ("GNUmakefile" | path exists))
  let makeFlags = (attr makeFlags [])

  if not $hasMakefile and ($makeFlags | length) == 0 {
    print -e "no Makefile or custom installPhase, doing nothing"
    runHook postInstall
    return
  }

  let prefix = $env.out
  mkdir $prefix

  let installFlags = (attr installFlags [])
  let installTargets = (attr installTargets ["install"])
  let cores = $env.NIX_BUILD_CORES
  let parallelFlag = if (attrBool enableParallelInstalling true) { [$"-j($cores)"] } else { [] }

  x make ...$installTargets ...$parallelFlag ...$makeFlags ...$installFlags

  runHook postInstall
}

def --env fixupPhase [] {
  # Ensure all output directories exist (even if empty)
  for outputName in (getAllOutputNames) {
    let outputPath = (getOutput $outputName)
    if not ($outputPath | path exists) {
      mkdir $outputPath
    }
  }

  # Make everything writable for strip et al.
  for outputName in (getAllOutputNames) {
    let outputPath = (getOutput $outputName)
    if ($outputPath | path exists) {
      ^chmod -R u+w -- $outputPath
    }
  }

  runHook preFixup

  # Run fixup hooks on each output
  for outputName in (getAllOutputNames) {
    let outputPath = (getOutput $outputName)
    if ($outputPath | path exists) {
      load-env {prefix: $outputPath}
      # Run built-in fixup operations
      move-lib64 moveLib64
      move-sbin moveSbin
      move-docs moveDocs
      compress-man-pages compressManPages
      patch-shebangs patchShebangsAuto $outputPath
      strip doStrip $outputPath
      # Run user-registered fixup hooks
      runHook fixupOutput
    }
  }

  # Record propagated dependencies
  propagated-deps recordPropagatedDeps

  runHook postFixup
}

def --env installCheckPhase [] {
  runHook preInstallCheck

  # Check for phase override
  let override = ($env | get -o __installCheckPhase)
  if $override != null {
    do $override
  } else {
    let phaseStr = (attr installCheckPhase)
    if $phaseStr != null and ($phaseStr | describe) == "string" {
      evalNu $phaseStr
    }
  }

  runHook postInstallCheck
}

# ---------------------------------------------------------------------------
# Phase runner
# ---------------------------------------------------------------------------

def --env runPhase [phase: string] {
  # Skip conditions
  let skipMap = {
    unpackPhase: dontUnpack
    patchPhase: dontPatch
    configurePhase: dontConfigure
    buildPhase: dontBuild
    installPhase: dontInstall
    fixupPhase: dontFixup
  }

  # Phases that require an opt-in
  let optInMap = {
    checkPhase: doCheck
    installCheckPhase: doInstallCheck
  }

  # Check skip
  let skipAttr = ($skipMap | get -o $phase)
  if $skipAttr != null and (attrBool $skipAttr) {
    return
  }

  # Check opt-in
  let optInAttr = ($optInMap | get -o $phase)
  if $optInAttr != null and not (attrBool $optInAttr) {
    return
  }

  note "phase" $phase
  print -e $"Running phase: ($phase)"

  let start = (date now)

  # Execute the phase
  match $phase {
    "unpackPhase" => { unpackPhase }
    "patchPhase" => { patchPhase }
    "configurePhase" => { configurePhase }
    "buildPhase" => { buildPhase }
    "checkPhase" => { checkPhase }
    "installPhase" => { installPhase }
    "fixupPhase" => { fixupPhase }
    "installCheckPhase" => { installCheckPhase }
    _ => {
      # Custom phase — try to eval as nushell code
      let phaseStr = (attr $phase)
      if $phaseStr != null and ($phaseStr | describe) == "string" {
        evalNu $phaseStr
      } else {
        print -e $"unknown phase ($phase), skipping"
      }
    }
  }

  let elapsed = ((date now) - $start)
  print -e $"Phase ($phase) completed in ($elapsed)"
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def --env main [] {
  # Parse structured attrs
  let attrs = (open $env.NIX_ATTRS_JSON_FILE)
  load-env {__attrs: $attrs}

  print -e "nushell builder starting"

  # Set up environment
  setupEnvironment

  # Activate dependencies and build search paths
  activateDependencies

  # Define phase sequence
  let defaultPhases = [
    "unpackPhase"
    "patchPhase"
    "configurePhase"
    "buildPhase"
    "checkPhase"
    "installPhase"
    "fixupPhase"
    "installCheckPhase"
  ]

  let phases = (attr phases $defaultPhases)

  # Run all phases
  for phase in $phases {
    runPhase $phase
  }

  print -e "nushell builder finished"
}

# Run
main
