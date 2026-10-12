xcbuildBuildPhase() {
    export DSTROOT=$out

    local flagsArray=()
    concatTo flagsArray xcbuildFlags

    echoCmd 'running xcodebuild' "${flagsArray[@]}"

    xcodebuild SYMROOT=$PWD/Products OBJROOT=$PWD/Intermediates "${flagsArray[@]}" build
}

xcbuildInstallPhase () {
    # not implemented
    # xcodebuild install
    :
}

buildPhase=xcbuildBuildPhase
if [ -z "${installPhase-}" ]; then
    installPhase=xcbuildInstallPhase
fi

# if [ -d "*.xcodeproj" ]; then
#     buildPhase=xcbuildPhase
# fi
