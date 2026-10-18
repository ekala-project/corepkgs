addAwsCCommonModuleDir() {
    setCMakeEntry CMAKE_MODULE_PATH "@out@/lib/cmake"
}

postHooks+=(addAwsCCommonModuleDir)
