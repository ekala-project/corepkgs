# shellcheck shell=bash

pnpmBuildHook() {
    echo "Executing pnpmBuildHook"

    if [[ $pnpmRoot ]]; then
      pushd "$pnpmRoot"
    fi

    local -a filterFlags
    if [[ -n "${pnpmWorkspaces-}" ]]; then
        local IFS=" "
        for ws in $pnpmWorkspaces; do
            filterFlags+=("--filter=$ws")
        done
    fi

    local -a buildFlagsArray
    if [[ -n "${pnpmBuildFlags-}" ]]; then
        read -ra buildFlagsArray <<< "${pnpmBuildFlags-}"
    fi

    echo
    echo "Running"
    echo "pnpm run ${filterFlags[*]} ${pnpmBuildScript:-build} ${buildFlagsArray[*]}"
    echo

    if ! pnpm run "${filterFlags[@]}" "${pnpmBuildScript:-build}" "${buildFlagsArray[@]}"; then
        echo
        echo "ERROR: 'pnpm run ${pnpmBuildScript:-build}' failed"
        echo
        echo "Here are a few things you can try, depending on the error:"
        echo "1. Make sure your build script (${pnpmBuildScript:-build}) exists"
        echo '   If there isnt one, set `dontPnpmBuild = true`.'
        echo

        exit 1
    fi

    if [[ $pnpmRoot ]]; then
      popd
    fi

    echo "Finished pnpmBuildHook"
}

pnpmBuildPhase() {
  runHook preBuild

  pnpmBuildHook

  runHook postBuild
}

if [ -z "${dontPnpmBuild-}" ] && [ -z "${buildPhase-}" ]; then
    buildPhase=pnpmBuildPhase
fi
