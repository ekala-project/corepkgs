# cmake setup-hook is still sourced by default if cmake was defined
if [ -z "${configurePhase-}" ]; then
    setOutputFlags=
    configurePhase=cmakeConfigurePhase
fi
