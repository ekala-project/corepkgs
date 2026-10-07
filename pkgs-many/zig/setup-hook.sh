# shellcheck shell=bash

# shellcheck disable=SC2034
readonly zigDefaultCpuFlag=@zigDefaultCpuFlag@
readonly zigDefaultOptimizeFlag=@zigDefaultOptimizeFlag@

zigConfigurePhase() {
    runHook preConfigure

    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"

    runHook postConfigure
}

zigBuildPhase() {
    runHook preBuild

    local buildCores=1

    if [ "${enableParallelBuilding-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    local -a flagsArray=(
        "-j$buildCores"
    )
    concatTo flagsArray \
        zigBuildFlags zigBuildFlagsArray

    if [ -z "${dontSetZigDefaultFlags-}" ]; then
        concatTo flagsArray \
            zigDefaultCpuFlag zigDefaultOptimizeFlag
    fi

    echoCmd 'zig build flags' "${flagsArray[@]}"
    TERM=dumb zig build "${flagsArray[@]}" --verbose

    runHook postBuild
}

zigCheckPhase() {
    runHook preCheck

    local buildCores=1

    if [ "${enableParallelChecking-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    local -a flagsArray=(
        "-j$buildCores"
    )
    concatTo flagsArray \
        zigCheckFlags zigCheckFlagsArray

    if [ -z "${dontSetZigDefaultFlags-}" ]; then
        concatTo flagsArray \
            zigDefaultCpuFlag zigDefaultOptimizeFlag
    fi

    echoCmd 'zig check flags' "${flagsArray[@]}"
    TERM=dumb zig build test "${flagsArray[@]}" --verbose

    runHook postCheck
}

zigInstallPhase() {
    runHook preInstall

    local buildCores=1

    if [ "${enableParallelInstalling-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    local -a flagsArray=(
        "-j$buildCores"
    )

    concatTo flagsArray \
        zigBuildFlags zigBuildFlagsArray \
        zigInstallFlags zigInstallFlagsArray

    if [ -z "${dontSetZigDefaultFlags-}" ]; then
        concatTo flagsArray \
            zigDefaultCpuFlag zigDefaultOptimizeFlag
    fi

    if [ -z "${dontAddPrefix-}" ] && [ -n "$prefix" ]; then
        # Zig does not recognize `--prefix=/dir/`, only `--prefix /dir/`
        flagsArray+=("${prefixKey:---prefix}" "$prefix")
    fi

    echoCmd 'zig install flags' "${flagsArray[@]}"
    TERM=dumb zig build install "${flagsArray[@]}" --verbose

    runHook postInstall
}

if [ -z "${dontUseZigConfigure-}" ] && [ -z "${configurePhase-}" ]; then
    configurePhase=zigConfigurePhase
fi

if [ -z "${dontUseZigBuild-}" ] && [ -z "${buildPhase-}" ]; then
    buildPhase=zigBuildPhase
fi

if [ -z "${dontUseZigCheck-}" ] && [ -z "${checkPhase-}" ]; then
    checkPhase=zigCheckPhase
fi

if [ -z "${dontUseZigInstall-}" ] && [ -z "${installPhase-}" ]; then
    installPhase=zigInstallPhase
fi
