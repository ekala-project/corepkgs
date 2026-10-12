# shellcheck shell=bash

justBuildPhase() {
    local flagsArray=()
    concatTo flagsArray justFlags justFlagsArray

    echoCmd 'build flags' "${flagsArray[@]}"
    just "${flagsArray[@]}"
}

justCheckPhase() {
    if [ -z "${checkTarget:-}" ]; then
        if just -n test >/dev/null 2>&1; then
            checkTarget="test"
        fi
    fi

    if [ -z "${checkTarget:-}" ]; then
        echo "no test target found in just, doing nothing"
    else
        local flagsArray=()
        concatTo flagsArray justFlags justFlagsArray checkTarget

        echoCmd 'check flags' "${flagsArray[@]}"
        just "${flagsArray[@]}"
    fi
}

justInstallPhase() {
    local flagsArray=()
    concatTo flagsArray justFlags justFlagsArray installTargets=install

    echoCmd 'install flags' "${flagsArray[@]}"
    just "${flagsArray[@]}"
}

if [ -z "${dontUseJustBuild-}" ] && [ -z "${buildPhase-}" ]; then
    buildPhase=justBuildPhase
fi

if [ -z "${dontUseJustCheck-}" ] && [ -z "${checkPhase-}" ]; then
    checkPhase=justCheckPhase
fi

if [ -z "${dontUseJustInstall-}" ] && [ -z "${installPhase-}" ]; then
    installPhase=justInstallPhase
fi
