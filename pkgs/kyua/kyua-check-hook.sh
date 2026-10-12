kyuaCheckPhase() {
    # Kyua expects to save test results in ~/.kyua/store
    HOME=$TMPDIR kyua test
}

if [ -z "${dontUseKyuaCheck-}" ] && [ -z "${checkPhase-}" ]; then
    checkPhase=kyuaCheckPhase
fi
