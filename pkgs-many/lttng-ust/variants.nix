{
  v2_12 = rec {
    version = "2.12.2";
    src-url = "https://lttng.org/files/lttng-ust/lttng-ust-${version}.tar.bz2";
    src-hash = "sha256-vNDwZLbKiMcthOdg6sNHKuXIKEEcY0Q1kivun841n8c=";
    useAutoreconf = false;
    withManpages = false;
  };

  v2_15 = rec {
    version = "2.15.1";
    src-url = "https://github.com/lttng/lttng-ust/archive/refs/tags/v${version}.tar.gz";
    src-hash = "sha256-3hjg4zIIO20zS6ojDjZttPFeJmSDywI493ZCWqNcWcA=";
    useAutoreconf = true;
    withManpages = true;
  };
}
