#!/bin/bash

# Zig setup hook for building Zig projects

zigConfigurePhase() {
    runHook preConfigure

    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"

    runHook postConfigure
}

zigBuildPhase() {
    runHook preBuild

    local flagsArray=(
        ${zigBuildFlags[@]}
        -Doptimize=ReleaseSafe
    )

    zig build "${flagsArray[@]}"

    runHook postBuild
}

zigInstallPhase() {
    runHook preInstall

    zig build install --prefix "$out"

    runHook postInstall
}

if [ -z "${dontUseZigConfigure-}" ]; then
    configurePhase=zigConfigurePhase
fi

if [ -z "${dontUseZigBuild-}" ]; then
    buildPhase=zigBuildPhase
fi

if [ -z "${dontUseZigInstall-}" ]; then
    installPhase=zigInstallPhase
fi
