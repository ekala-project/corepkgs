addCMakeParams() {
    # NIXPKGS_CMAKE_PREFIX_PATH is like CMAKE_PREFIX_PATH except cmake
    # will not search it for programs
    addToSearchPath NIXPKGS_CMAKE_PREFIX_PATH $1
}

fixCmakeFiles() {
    # Replace occurences of /usr and /opt by /var/empty.
    echo "fixing cmake files..."
    find "$1" -type f \( -name "*.cmake" -o -name "*.cmake.in" -o -name CMakeLists.txt \) -print |
        while read fn; do
            sed -e 's^/usr\([ /]\|$\)^/var/empty\1^g' -e 's^/opt\([ /]\|$\)^/var/empty\1^g' < "$fn" > "$fn.tmp"
            mv "$fn.tmp" "$fn"
        done
}

# --- cmakeEntries helpers ---
# cmakeEntries is a bash associative array of CMake cache entries.
# When passed as a Nix attrset, structured attrs creates the array automatically.
# These helpers manipulate it and convert entries to -DKEY=VALUE flags.

if ! declare -p cmakeEntries &>/dev/null 2>&1; then
    declare -gA cmakeEntries
fi

# Canonicalize a value to CMake boolean ON/OFF.
_cmakeBoolValue() {
    case "${1,,}" in
        1|true|on|yes|y) echo "ON" ;;
        ""|0|false|off|no|n|ignore|notfound) echo "OFF" ;;
        *) echo "$1" ;;
    esac
}

# Set a string entry, overwriting any existing value.
setCMakeEntry() {
    cmakeEntries[$1]="$2"
}

# Set a boolean entry (canonicalized to ON/OFF), overwriting any existing value.
setCMakeEntryBool() {
    cmakeEntries[$1]="$(_cmakeBoolValue "$2")"
}

# Set a string entry only if the key is not already present.
# Used by the hook to set defaults that user-specified cmakeEntries can override.
prependCMakeEntry() {
    if ! [[ -v "cmakeEntries[$1]" ]]; then
        cmakeEntries[$1]="$2"
    fi
}

# Set a boolean entry only if the key is not already present.
prependCMakeEntryBool() {
    if ! [[ -v "cmakeEntries[$1]" ]]; then
        cmakeEntries[$1]="$(_cmakeBoolValue "$2")"
    fi
}

# Remove an entry.
removeCMakeEntry() {
    unset "cmakeEntries[$1]"
}

# Get an entry value, or the optional default if not present.
getCMakeEntry() {
    if [[ -v "cmakeEntries[$1]" ]]; then
        echo "${cmakeEntries[$1]}"
    elif (( $# >= 2 )); then
        echo "$2"
    else
        echo "getCMakeEntry: key '$1' not found and no default provided" >&2
        return 1
    fi
}

# Append -DKEY=VALUE flags for all cmakeEntries into the named array variable.
concatCMakeEntryFlagsTo() {
    local -n _targetArray="$1"
    local _key
    for _key in "${!cmakeEntries[@]}"; do
        _targetArray+=("-D${_key}=${cmakeEntries[$_key]}")
    done
}

# The docdir flag needs to include PROJECT_NAME as per GNU guidelines,
# try to extract it from CMakeLists.txt.
parseShareDocName() {
    local cmakeLists="$cmakeDir/CMakeLists.txt"
    if [[ -f "$cmakeLists" ]]; then
        local shareDocName
        shareDocName="$(grep --only-matching --perl-regexp --ignore-case '\bproject\s*\(\s*"?\K([^[:space:]")]+)' <"$cmakeLists" | head -n1)"
    fi
    # The argument sometimes contains garbage or variable interpolation.
    # When that is the case, let's fall back to the derivation name.
    if [[ -z "$shareDocName" ]] || echo "$shareDocName" | grep -q '[^a-zA-Z0-9_+-]'; then
        if [[ -n "${pname-}" ]]; then
            shareDocName="$pname"
        else
            shareDocName="$(echo "$name" | sed 's/-[^a-zA-Z].*//')"
        fi
    fi
    echo "$shareDocName"
}

cmakeConfigurePhase() {
    runHook preConfigure

    # default to CMake defaults if unset
    : ${cmakeBuildDir:=build}

    export CTEST_OUTPUT_ON_FAILURE=1
    if [ -n "${enableParallelChecking-1}" ]; then
        export CTEST_PARALLEL_LEVEL=$NIX_BUILD_CORES
    fi

    if [ -z "${dontFixCmake-}" ]; then
        fixCmakeFiles .
    fi

    if [ -z "${dontUseCmakeBuildDir-}" ]; then
        mkdir -p "$cmakeBuildDir"
        cd "$cmakeBuildDir"
        : ${cmakeDir:=..}
    else
        : ${cmakeDir:=.}
    fi

    if [ -z "${dontAddPrefix-}" ]; then
        prependCMakeEntry "CMAKE_INSTALL_PREFIX" "$prefix"
    fi

    # We should set the proper `CMAKE_SYSTEM_NAME`.
    # http://www.cmake.org/Wiki/CMake_Cross_Compiling
    #
    # Unfortunately cmake seems to expect absolute paths for ar, ranlib, and
    # strip. Otherwise they are taken to be relative to the source root of the
    # package being built.
    prependCMakeEntry "CMAKE_CXX_COMPILER" "$CXX"
    prependCMakeEntry "CMAKE_C_COMPILER" "$CC"
    prependCMakeEntry "CMAKE_AR" "$(command -v $AR)"
    prependCMakeEntry "CMAKE_RANLIB" "$(command -v $RANLIB)"
    prependCMakeEntry "CMAKE_STRIP" "$(command -v $STRIP)"

    # on macOS we want to prefer Unix-style headers to Frameworks
    # because we usually do not package the framework
    prependCMakeEntry "CMAKE_FIND_FRAMEWORK" "LAST"

    # we never want to use the global macOS SDK
    prependCMakeEntry "CMAKE_OSX_SYSROOT" ""

    # correctly detect our clang compiler
    prependCMakeEntry "CMAKE_POLICY_DEFAULT_CMP0025" "NEW"

    # This installs shared libraries with a fully-specified install
    # name. By default, cmake installs shared libraries with just the
    # basename as the install name, which means that, on Darwin, they
    # can only be found by an executable at runtime if the shared
    # libraries are in a system path or in the same directory as the
    # executable. This flag makes the shared library accessible from its
    # nix/store directory.
    prependCMakeEntry "CMAKE_INSTALL_NAME_DIR" "${!outputLib}/lib"

    if [[ -z "$shareDocName" ]]; then
        shareDocName=$(parseShareDocName)
    fi

    # This ensures correct paths with multiple output derivations
    # It requires the project to use variables from GNUInstallDirs module
    # https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
    prependCMakeEntry "CMAKE_INSTALL_BINDIR" "${!outputBin}/bin"
    prependCMakeEntry "CMAKE_INSTALL_SBINDIR" "${!outputBin}/sbin"
    prependCMakeEntry "CMAKE_INSTALL_INCLUDEDIR" "${!outputInclude}/include"
    prependCMakeEntry "CMAKE_INSTALL_OLDINCLUDEDIR" "${!outputInclude}/include"
    prependCMakeEntry "CMAKE_INSTALL_MANDIR" "${!outputMan}/share/man"
    prependCMakeEntry "CMAKE_INSTALL_INFODIR" "${!outputInfo}/share/info"
    prependCMakeEntry "CMAKE_INSTALL_DOCDIR" "${!outputDoc}/share/doc/${shareDocName}"
    prependCMakeEntry "CMAKE_INSTALL_LIBDIR" "${!outputLib}/lib"
    prependCMakeEntry "CMAKE_INSTALL_LIBEXECDIR" "${!outputLib}/libexec"
    prependCMakeEntry "CMAKE_INSTALL_LOCALEDIR" "${!outputLib}/share/locale"

    # Don’t build tests when doCheck = false
    if [ -z "${doCheck-}" ]; then
        prependCMakeEntryBool "BUILD_TESTING" "OFF"
    fi

    # Always build Release, to ensure optimisation flags
    prependCMakeEntry "CMAKE_BUILD_TYPE" "${cmakeBuildType:-Release}"

    # Disable user package registry to avoid potential side effects
    # and unecessary attempts to access non-existent home folder
    # https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#disabling-the-package-registry
    prependCMakeEntryBool "CMAKE_EXPORT_NO_PACKAGE_REGISTRY" "ON"
    prependCMakeEntryBool "CMAKE_FIND_USE_PACKAGE_REGISTRY" "OFF"
    prependCMakeEntryBool "CMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY" "OFF"

    if [ "${buildPhase-}" = ninjaBuildPhase ]; then
        prependToVar cmakeFlags "-GNinja"
    fi

    local flagsArray=()
    concatCMakeEntryFlagsTo flagsArray
    concatTo flagsArray cmakeFlags cmakeFlagsArray

    echo "cmake flags: ${flagsArray[*]}"

    cmake "$cmakeDir" "${flagsArray[@]}"

    if ! [[ -v enableParallelBuilding ]]; then
        enableParallelBuilding=1
        echo "cmake: enabled parallel building"
    fi

    if ! [[ -v enableParallelInstalling ]]; then
        enableParallelInstalling=1
        echo "cmake: enabled parallel installing"
    fi

    runHook postConfigure
}

_fixCmakeIncludeDir() {
    # When the include output is different from the main output, CMake-generated
    # target files may contain INTERFACE_INCLUDE_DIRECTORIES entries relative to
    # _IMPORT_PREFIX (e.g. "${_IMPORT_PREFIX}/include") that point into the main
    # output where headers no longer exist.  Rewrite these to the absolute
    # include output path so downstream find_package() calls work.
    if [ "${!outputInclude}" = "${!outputDev}" ] && [ "${!outputInclude}" = "$out" ]; then
        return
    fi
    local f
    for f in $(find "${!outputLib}" "$out" -name '*.cmake' 2>/dev/null); do
        if grep -q '${_IMPORT_PREFIX}/include' "$f" 2>/dev/null; then
            echo "Patching CMake include path in $f to ${!outputInclude}/include"
            sed -i "s|\\\${_IMPORT_PREFIX}/include|${!outputInclude}/include|g" "$f"
        fi
    done
}

postFixupHooks+=(_fixCmakeIncludeDir)

addEnvHooks "$targetOffset" addCMakeParams

makeCmakeFindLibs(){
  isystem_seen=
  iframework_seen=
  for flag in ${NIX_CFLAGS_COMPILE-} ${NIX_LDFLAGS-}; do
    if test -n "$isystem_seen" && test -d "$flag"; then
      isystem_seen=
      addToSearchPath CMAKE_INCLUDE_PATH "${flag}"
    elif test -n "$iframework_seen" && test -d "$flag"; then
      iframework_seen=
      addToSearchPath CMAKE_FRAMEWORK_PATH "${flag}"
    else
      isystem_seen=
      iframework_seen=
      case $flag in
        -I*)
          addToSearchPath CMAKE_INCLUDE_PATH "${flag:2}"
          ;;
        -L*)
          addToSearchPath CMAKE_LIBRARY_PATH "${flag:2}"
          ;;
        -F*)
          addToSearchPath CMAKE_FRAMEWORK_PATH "${flag:2}"
          ;;
        -isystem)
          isystem_seen=1
          ;;
        -iframework)
          iframework_seen=1
          ;;
      esac
    fi
  done
}

# not using setupHook, because it could be a setupHook adding additional
# include flags to NIX_CFLAGS_COMPILE
postHooks+=(makeCmakeFindLibs)
