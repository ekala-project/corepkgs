# hook for running busted
# shellcheck shell=bash
echo "Sourcing busted-check-hook.sh"

bustedCheckPhase () {
    echo "Executing bustedCheckPhase"

    if command -v nlua && [ -z "${bustedNoNlua-}" ]; then
      bustedFlags+=("--lua=nlua")
    fi

    busted "${bustedFlags[@]}"

    echo "Finished executing bustedCheckPhase"
}

if [ -z "${dontBustedCheck-}" ] && [ -z "${checkPhase-}" ]; then
    echo "Using bustedCheckPhase"
    checkPhase+=" bustedCheckPhase"
fi


