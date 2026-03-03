{
  v2_5_35 = rec {
    version = "2.5.35";
    src-hash = "sha256-0wh06nix8bd4w1aq4k2fbbkdq5i30a9lxz3xczf3ff28yy0kfwzm=";
    # Uses GitHub archive format instead of releases
    src-url = "https://github.com/westes/flex/archive/flex-${
      builtins.replaceStrings [ "." ] [ "-" ] version
    }.tar.gz";
    # v2.5.35 needs flex to build itself (bootstrap dependency)
    needsFlexBootstrap = true;
    # v2.5.35 needs texinfo in addition to help2man
    needsTexinfo = true;
    # Tests fail for this version
    doCheck = false;
    # Older meta homepage
    metaHomepage = "https://flex.sourceforge.net/";
  };

  v2_6_4 = rec {
    version = "2.6.4";
    src-hash = "sha256-6HquAyvwfCb4WsDtMlCZjDdiHZX4vXSLMfFbM8Re6ZU=";
    src-url = "https://github.com/westes/flex/releases/download/v${version}/flex-${version}.tar.gz";
    # This version needs the glibc-2.26 patch (will be part of 2.6.5)
    # Using fetchurl directly to avoid 'fetchpatch' dependency for bootstrap
    glibcPatchUrl = "https://raw.githubusercontent.com/lede-project/source/0fb14a2b1ab2f82ce63f4437b062229d73d90516/tools/flex/patches/200-build-AC_USE_SYSTEM_EXTENSIONS-in-configure.ac.patch";
    glibcPatchHash = "sha256-eSDA0hIIfQbXx0DP1dTQU2uIqBxIXjbB6O+E134g91Y=";
    metaHomepage = "https://github.com/westes/flex";
  };
}
