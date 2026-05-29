# Setup hook for storing test sources in a separate output
# shellcheck shell=bash

echo "Sourcing python-output-test-src-hook.sh"

pythonOutputTestSrcPhase() {
    echo "Executing pythonOutputTestSrcPhase"
    if [[ -z "${testPaths:-}" ]]; then
        cat >&2 <<EOF
testPaths is empty.
Ensure the testPaths attribute lists at least one path relative to the source root.
EOF
        return 1
    fi
    # shellcheck disable=SC2154
    mkdir -p "$test_src"
    # Copy each entry of testPaths (files or directories, relative to the
    # source root) into the test_src output, preserving directory structure.
    local p
    # shellcheck disable=SC2154
    for p in ${testPaths}; do
        if [[ -e "$p" ]]; then
            cp -R --parents "$p" "$test_src/"
        else
            echo "error: testPaths entry '$p' not found" >&2
            return 1
        fi
    done
    # Include pytest/unittest config and root-level conftest.py so that
    # test discovery and configuration work in the derived test derivation.
    local f
    for f in conftest.py pytest.ini setup.cfg pyproject.toml tox.ini; do
        if [[ -f "$f" ]]; then
            cp "$f" "$test_src/"
        fi
    done
    echo "Finished executing pythonOutputTestSrcPhase"
}

appendToVar preFixupPhases pythonOutputTestSrcPhase
