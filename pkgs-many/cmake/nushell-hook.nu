# CMake nushell hook for mkEkaPackage
#
# This script is passed as a subcommand argument when invoked by setup.nu.
# Usage in mkEkaPackage:
#   commands = scope: {
#     inherit (scope) cmake ninja;
#     cmakeHook = scope.cmake.nushellHook;
#   };
#
# The hook overrides configurePhase, buildPhase, checkPhase, and installPhase
# to use cmake/ninja instead of make.

def main [phase: string] {
  let attrs = (open $env.NIX_ATTRS_JSON_FILE)

  match $phase {
    "configure" => { cmakeConfigure $attrs }
    "build" => { cmakeBuild $attrs }
    "check" => { cmakeCheck $attrs }
    "install" => { cmakeInstall $attrs }
    _ => { print -e $"cmake hook: unknown phase ($phase)" }
  }
}

def cmakeConfigure [attrs: record] {
  let cmakeBuildDir = ($attrs | get -o cmakeBuildDir | default "build")
  let cmakeFlags = ($attrs | get -o cmakeFlags | default [])
  let prefix = $env.out
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")

  mkdir $cmakeBuildDir
  cd $cmakeBuildDir

  # Collect dependency paths for CMAKE_PREFIX_PATH
  let buildInputs = ($attrs | get -o buildInputs | default [])
  let nativeBuildInputs = ($attrs | get -o nativeBuildInputs | default [])
  let allDeps = ($buildInputs ++ $nativeBuildInputs | where {|d| not ($d | str ends-with ".nu")})
  let cmakePrefixPath = ($allDeps | str join ";")

  mut flags = [
    $"-DCMAKE_INSTALL_PREFIX=($prefix)"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    $"-DCMAKE_PREFIX_PATH=($cmakePrefixPath)"
    "-DBUILD_SHARED_LIBS=ON"
  ]

  $flags = ($flags | append $cmakeFlags)

  print -e $"+ cmake -S .. -B . -G Ninja ($flags | str join ' ')"
  ^cmake -S .. -B . -G Ninja ...$flags
}

def cmakeBuild [attrs: record] {
  let cmakeBuildDir = ($attrs | get -o cmakeBuildDir | default "build")
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")

  cd $cmakeBuildDir
  print -e $"+ cmake --build . -j($cores)"
  ^cmake --build . $"-j($cores)"
}

def cmakeCheck [attrs: record] {
  let cmakeBuildDir = ($attrs | get -o cmakeBuildDir | default "build")
  let cores = ($env | get -o NIX_BUILD_CORES | default "1")

  cd $cmakeBuildDir
  print -e $"+ ctest --output-on-failure -j($cores)"
  ^ctest --output-on-failure $"-j($cores)"
}

def cmakeInstall [attrs: record] {
  let cmakeBuildDir = ($attrs | get -o cmakeBuildDir | default "build")

  cd $cmakeBuildDir
  print -e "+ cmake --install ."
  ^cmake --install .
}
