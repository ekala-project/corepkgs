{
  v2_5 = rec {
    version = "2.5.39";
    src-hash = "sha256-cd0bWBWMk1AnEEyDDAGeSMcyUHCK9d70XqJWx4kxiUg=";
    needsTexinfo = true;
  };

  v2_6 = rec {
    version = "2.6.4";
    src-hash = "sha256-6HquAyvwfCb4WsDtMlCZjDdiHZX4vXSLMfFbM8Re6ZU=";
    # This version needs the glibc-2.26 patch (will be part of 2.6.5)
    # Using fetchurl directly to avoid 'fetchpatch' dependency for bootstrap
    glibcPatchUrl = "https://raw.githubusercontent.com/lede-project/source/0fb14a2b1ab2f82ce63f4437b062229d73d90516/tools/flex/patches/200-build-AC_USE_SYSTEM_EXTENSIONS-in-configure.ac.patch";
    glibcPatchHash = "sha256-eSDA0hIIfQbXx0DP1dTQU2uIqBxIXjbB6O+E134g91Y=";
  };
}
