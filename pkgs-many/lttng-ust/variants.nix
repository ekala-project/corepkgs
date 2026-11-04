{
  v2_12 = rec {
    version = "2.12.2";
    src-url = "https://lttng.org/files/lttng-ust/lttng-ust-${version}.tar.bz2";
    src-hash = "sha256-vNDwZLbKiMcthOdg6sNHKuXIKEEcY0Q1kivun841n8c=";
    useAutoreconf = false;
    withManpages = false;
  };

  v2_15 = rec {
    version = "2.16.0";
    src-url = "https://github.com/lttng/lttng-ust/archive/refs/tags/v${version}.tar.gz";
    src-hash = "sha256-5pxcRz4PDnR7Hiw3owe0K+OdxWscVfuD/t1d6A87xLI=";
    useAutoreconf = true;
    withManpages = true;
  };
}
