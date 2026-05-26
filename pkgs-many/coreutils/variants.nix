{
  v9_8 = rec {
    version = "9.8";
    src-url = "mirror://gnu/coreutils/coreutils-${version}.tar.xz";
    src-hash = "sha256-5tT9LYUskUGhwqGKE9FGoM1+RRlfcik6TkwETsbMyhU=";
  };

  # coreutils: minimal variant for bootstrapping (no openssl, no docs)
  minimal = rec {
    version = "9.8";
    src-url = "mirror://gnu/coreutils/coreutils-${version}.tar.xz";
    src-hash = "sha256-5tT9LYUskUGhwqGKE9FGoM1+RRlfcik6TkwETsbMyhU=";
    isMinimal = true;
  };

  # coreutils-full: all features enabled including openssl
  full = rec {
    version = "9.8";
    src-url = "mirror://gnu/coreutils/coreutils-${version}.tar.xz";
    src-hash = "sha256-5tT9LYUskUGhwqGKE9FGoM1+RRlfcik6TkwETsbMyhU=";
    isMinimal = false;
  };

  # coreutils-prefixed: utilities prefixed with "g" (e.g., gcp, gls)
  # Useful on platforms where the GNU coreutils should not shadow system tools.
  prefixed = rec {
    version = "9.8";
    src-url = "mirror://gnu/coreutils/coreutils-${version}.tar.xz";
    src-hash = "sha256-5tT9LYUskUGhwqGKE9FGoM1+RRlfcik6TkwETsbMyhU=";
    isMinimal = true;
    withPrefix = true;
    singleBinary = false;
  };
}
