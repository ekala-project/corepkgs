# Meson nushell hook for mkEkaPackage
#
# Usage in mkEkaPackage:
#   commands = scope: {
#     inherit (scope) ninja pkg-config;
#     mesonHook = scope.meson.nushellHook;
#   };
#
# Overrides configurePhase, buildPhase, checkPhase, and installPhase
# to use meson/ninja.

def main [phase: string] {
  let attrs = (open $env.NIX_ATTRS_JSON_FILE)

  match $phase {
    "configure" => { mesonConfigure $attrs }
    "build" => { mesonBuild $attrs }
    "check" => { mesonCheck $attrs }
    "install" => { mesonInstall $attrs }
    _ => { print -e $"meson hook: unknown phase ($phase)" }
  }
}

def mesonConfigure [attrs: record] {
  let mesonBuildDir = ($attrs | get -o mesonBuildDir | default "build")
  let mesonFlags = ($attrs | get -o mesonFlags | default [])
  let prefix = $env.out
  let mesonBuildType = ($attrs | get -o mesonBuildType | default "release")

  mkdir $mesonBuildDir

  mut flags = [
    $"--prefix=($prefix)"
    "--libdir=lib"
    $"--buildtype=($mesonBuildType)"
    "--default-library=shared"
    "--wrap-mode=nodownload"
    "--auto-features=enabled"
  ]

  $flags = ($flags | append $mesonFlags)

  print -e $"+ meson setup ($mesonBuildDir) . ($flags | str join ' ')"
  ^meson setup $mesonBuildDir . ...$flags
}

def mesonBuild [attrs: record] {
  let mesonBuildDir = ($attrs | get -o mesonBuildDir | default "build")
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")

  print -e $"+ ninja -C ($mesonBuildDir) -j($cores)"
  ^ninja -C $mesonBuildDir $"-j($cores)"
}

def mesonCheck [attrs: record] {
  let mesonBuildDir = ($attrs | get -o mesonBuildDir | default "build")
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")

  print -e $"+ meson test -C ($mesonBuildDir) --no-rebuild --print-errorlogs"
  ^meson test -C $mesonBuildDir --no-rebuild --print-errorlogs $"--num-processes=($cores)"
}

def mesonInstall [attrs: record] {
  let mesonBuildDir = ($attrs | get -o mesonBuildDir | default "build")

  print -e $"+ meson install -C ($mesonBuildDir) --no-rebuild"
  ^meson install -C $mesonBuildDir --no-rebuild
}
