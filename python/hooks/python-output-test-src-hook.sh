# Setup hook for storing test sources in a separate output
# shellcheck shell=bash

echo "Sourcing python-output-test-src-hook.sh"

pythonOutputTestSrcPhase() {
    echo "Executing pythonOutputTestSrcPhase"
    if [[ -n "${testDir:-}" && -d "$testDir" ]]; then
        # shellcheck disable=SC2154
        mkdir -p "$test_src"
        cp -R "$testDir" "$test_src/"
    else
        cat >&2 <<EOF
testDir='${testDir:-}' does not exist in the source tree.
Ensure the testDir attribute points to a valid directory relative to the source root.
EOF
        return 1
    fi
    echo "Finished executing pythonOutputTestSrcPhase"
}

appendToVar preFixupPhases pythonOutputTestSrcPhase
