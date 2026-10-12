# Setup hook for eggs
echo "Sourcing egg-install-hook"

eggInstallPhase() {
    echo "Executing eggInstallPhase"

    mkdir -p "$out/@pythonSitePackages@"
    export PYTHONPATH="$out/@pythonSitePackages@:$PYTHONPATH"

    find
    @pythonInterpreter@ -m easy_install --prefix="$out" *.egg

    echo "Finished executing eggInstallPhase"
}

if [ -z "${dontUseEggInstall-}" ] && [ -z "${installPhase-}" ]; then
    echo "Using eggInstallPhase"
    installPhase=eggInstallPhase
fi
