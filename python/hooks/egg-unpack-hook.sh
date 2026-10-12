# Setup hook to use in case an egg is fetched
echo "Sourcing egg setup hook"

eggUnpackPhase() {
    echo "Executing eggUnpackPhase"

    cp "$src" "$(stripHash "$src")"
    echo "Finished executing eggUnpackPhase"
}

if [ -z "${dontUseEggUnpack-}" ] && [ -z "${unpackPhase-}" ]; then
    echo "Using eggUnpackPhase"
    unpackPhase=eggUnpackPhase
fi
