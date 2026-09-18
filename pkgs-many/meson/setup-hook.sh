# shellcheck shell=bash disable=SC2206

# --- mesonEntries helpers ---
# mesonEntries is a bash associative array of Meson -D options.
# When passed as a Nix attrset, structured attrs creates the array automatically.
# These helpers manipulate it and convert entries to -Dkey=value flags.

if ! declare -p mesonEntries &>/dev/null 2>&1; then
    declare -gA mesonEntries
fi

# Canonicalize a value to Meson boolean true/false.
_mesonBoolValue() {
    case "${1,,}" in
        1|true|on|yes|y) echo "true" ;;
        ""|0|false|off|no|n) echo "false" ;;
        *) echo "$1" ;;
    esac
}

# Canonicalize a value to Meson feature enabled/disabled/auto.
_mesonFeatureValue() {
    case "${1,,}" in
        1|true|on|yes|y|enabled) echo "enabled" ;;
        ""|0|false|off|no|n|disabled) echo "disabled" ;;
        auto) echo "auto" ;;
        *) echo "$1" ;;
    esac
}

# Set a string entry, overwriting any existing value.
setMesonEntry() {
    mesonEntries[$1]="$2"
}

# Set a boolean entry (canonicalized to true/false), overwriting any existing value.
setMesonEntryBool() {
    mesonEntries[$1]="$(_mesonBoolValue "$2")"
}

# Set a feature entry (canonicalized to enabled/disabled/auto), overwriting any existing value.
setMesonEntryFeature() {
    mesonEntries[$1]="$(_mesonFeatureValue "$2")"
}

# Set a string entry only if the key is not already present.
prependMesonEntry() {
    if ! [[ -v "mesonEntries[$1]" ]]; then
        mesonEntries[$1]="$2"
    fi
}

# Set a boolean entry only if the key is not already present.
prependMesonEntryBool() {
    if ! [[ -v "mesonEntries[$1]" ]]; then
        mesonEntries[$1]="$(_mesonBoolValue "$2")"
    fi
}

# Set a feature entry only if the key is not already present.
prependMesonEntryFeature() {
    if ! [[ -v "mesonEntries[$1]" ]]; then
        mesonEntries[$1]="$(_mesonFeatureValue "$2")"
    fi
}

# Remove an entry.
removeMesonEntry() {
    unset "mesonEntries[$1]"
}

# Get an entry value, or the optional default if not present.
getMesonEntry() {
    if [[ -v "mesonEntries[$1]" ]]; then
        echo "${mesonEntries[$1]}"
    elif (( $# >= 2 )); then
        echo "$2"
    else
        echo "getMesonEntry: key '$1' not found and no default provided" >&2
        return 1
    fi
}

# Append -Dkey=value flags for all mesonEntries into the named array variable.
concatMesonEntryFlagsTo() {
    local -n _targetArray="$1"
    local _key
    for _key in "${!mesonEntries[@]}"; do
        _targetArray+=("-D${_key}=${mesonEntries[$_key]}")
    done
}

mesonConfigurePhase() {
    runHook preConfigure

    : ${mesonBuildDir:=build}

    local flagsArray=()

    if [ -z "${dontAddPrefix-}" ]; then
        flagsArray+=("--prefix=$prefix")
    fi

    # If the package declares an "include" output, route headers there
    # automatically without requiring an explicit outputInclude attribute.
    if [ -n "${include-}" ] && [ "$outputInclude" = "$outputDev" ]; then
        outputInclude=include
    fi

    # See multiple-outputs.sh and meson’s coredata.py
    flagsArray+=(
        "--libdir=${!outputLib}/lib"
        "--libexecdir=${!outputLib}/libexec"
        "--bindir=${!outputBin}/bin"
        "--sbindir=${!outputBin}/sbin"
        "--includedir=${!outputInclude}/include"
        "--mandir=${!outputMan}/share/man"
        "--infodir=${!outputInfo}/share/info"
        "--localedir=${!outputLib}/share/locale"
        "-Dauto_features=${mesonAutoFeatures:-enabled}"
        "-Dwrap_mode=${mesonWrapMode:-nodownload}"
        "--buildtype=${mesonBuildType:-release}"
    )

    # --no-undefined is universally a bad idea on freebsd because environ is in the csu
    if [[ "@hostPlatform@" == *-freebsd ]]; then
        flagsArray+=("-Db_lundef=false")
    fi

    concatMesonEntryFlagsTo flagsArray
    concatTo flagsArray mesonFlags mesonFlagsArray

    echoCmd 'mesonConfigurePhase flags' "${flagsArray[@]}"

    meson setup "$mesonBuildDir" "${flagsArray[@]}"
    cd "$mesonBuildDir" || { echoCmd 'mesonConfigurePhase' "could not cd to $mesonBuildDir"; exit 1; }

    if ! [[ -v enableParallelBuilding ]]; then
        enableParallelBuilding=1
        echoCmd 'mesonConfigurePhase' "enabled parallel building"
    fi

    if [[ ${checkPhase-ninjaCheckPhase} = ninjaCheckPhase && -z $dontUseMesonCheck ]]; then
        checkPhase=mesonCheckPhase
    fi
    if [[ ${installPhase-ninjaInstallPhase} = ninjaInstallPhase && -z $dontUseMesonInstall ]]; then
        installPhase=mesonInstallPhase
    fi

    runHook postConfigure
}

mesonCheckPhase() {
    runHook preCheck

    local flagsArray=()
    concatTo flagsArray mesonCheckFlags mesonCheckFlagsArray

    if [ -z "${dontAddTimeoutMultiplier:-}" ]; then
        flagsArray+=("--timeout-multiplier=0")
    fi

    # Parallel checking is enabled by default.
    local buildCores=1
    if [ "${enableParallelChecking-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    TERM=dumb ninja -j"$buildCores" "${ninjaFlags[@]}" "${ninjaFlagsArray[@]}" meson-test-prereq

    echoCmd 'mesonCheckPhase flags' "${flagsArray[@]}"
    meson test --no-rebuild --print-errorlogs --max-lines=1000000 "${flagsArray[@]}"

    runHook postCheck
}

mesonInstallPhase() {
    runHook preInstall

    local flagsArray=()

    if [[ -n "$mesonInstallTags" ]]; then
        flagsArray+=("--tags" "$(concatStringsSep "," mesonInstallTags)")
    fi
    concatTo flagsArray mesonInstallFlags mesonInstallFlagsArray

    echoCmd 'mesonInstallPhase flags' "${flagsArray[@]}"
    meson install --no-rebuild "${flagsArray[@]}"

    runHook postInstall
}

if [ -z "${dontUseMesonConfigure-}" ] && [ -z "${configurePhase-}" ]; then
    # shellcheck disable=SC2034
    setOutputFlags=
    configurePhase=mesonConfigurePhase
fi
