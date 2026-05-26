{
  v2_45 = rec {
    version = "2.45.3";
    src-url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
    src-hash = "sha256-PLACEHOLDER";
  };

  v2_47 = rec {
    version = "2.47.2";
    src-url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
    src-hash = "sha256-PLACEHOLDER";
  };

  v2_51 = rec {
    version = "2.51.2";
    src-url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
    src-hash = "sha256-Iz1xQ6LVjmB1Xu6bdvVZ7HPqKzwpf1tQMWKs6VlmtOM=";
  };

  # gitFull: all features enabled (platform-dependent flags use null for auto-detection)
  full = rec {
    version = "2.51.2";
    src-url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
    src-hash = "sha256-Iz1xQ6LVjmB1Xu6bdvVZ7HPqKzwpf1tQMWKs6VlmtOM=";
    guiSupport = true;
    withSsh = true;
  };

  # gitMinimal: stripped-down git for bootstrapping
  minimal = rec {
    version = "2.51.2";
    src-url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
    src-hash = "sha256-Iz1xQ6LVjmB1Xu6bdvVZ7HPqKzwpf1tQMWKs6VlmtOM=";
    isMinimal = true;
  };
}
