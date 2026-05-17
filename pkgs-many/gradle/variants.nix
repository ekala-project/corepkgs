{
  v7 = rec {
    version = "7.6.6";
    hash = "sha256-Zz2XdvMDvHBI/DMp0jLW6/EFGweJO9nRFhb62ahnO+A=";
    # Gradle 7 uses JDK 17 by default
    defaultJavaSelector = (p: p.v17);
    # NOTE: Default JDKs must be LTS versions
    # See https://docs.gradle.org/current/userguide/compatibility.html
    meta = {
      knownVulnerabilities = [
        "Gradle 7 no longer receives security updates with the release of Gradle 9 on 31 July 2025. https://endoflife.date/gradle"
      ];
    };
    # The platforms supported by this Gradle package.
    # Gradle Native-Platform ships some binaries that
    # are compatible only with specific platforms.
    # As of 2022-04 this affects platform compatibility
    # of multiple Gradle releases, so this is used as default.
    # See https://github.com/gradle/native-platform#supported-platforms
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "i686-windows"
      "x86_64-cygwin"
      "x86_64-darwin"
      "x86_64-linux"
      "x86_64-windows"
    ];
    # Don't enable update script on this version
    enableUpdateScript = false;
  };

  v8 = rec {
    version = "8.14.4";
    hash = "sha256-8XcSmKcPbbWina9iN4xOGKF/wzybprFDYuDN9AYQOA0=";
    # Gradle 8 uses JDK 21 by default
    defaultJavaSelector = (p: p.v21);
    meta = { };
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "i686-windows"
      "x86_64-cygwin"
      "x86_64-darwin"
      "x86_64-linux"
      "x86_64-windows"
    ];
    # Only enable this on *one* version to avoid duplicate PRs.
    enableUpdateScript = true;
  };

  v9 = rec {
    version = "9.3.1";
    hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
    # Gradle 9 uses JDK 21 by default
    defaultJavaSelector = (p: p.v21);
    meta = { };
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "i686-windows"
      "x86_64-cygwin"
      "x86_64-darwin"
      "x86_64-linux"
      "x86_64-windows"
    ];
    # Don't enable update script on this version
    enableUpdateScript = false;
  };
}
