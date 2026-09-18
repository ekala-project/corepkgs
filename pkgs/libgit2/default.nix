{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  python3,
  zlib,
  libssh2,
  openssl,
  pcre2,
  libiconv,
  staticBuild ? stdenv.hostPlatform.isStatic,
  runUnitTests,
  # for passthru.tests
  libgit2-glib ? null,
  python3Packages,
  gitstatus ? null,
  llhttp,
  withGssapi ? false,
  krb5,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libgit2";
  version = "1.9.7";
  # also check the following packages for updates: python3Packages.pygit2 and libgit2-glib

  outputs = [
    "lib"
    "dev"
    "out"
  ];

  src = fetchFromGitHub {
    owner = "libgit2";
    repo = "libgit2";
    rev = "v${finalAttrs.version}";
    hash = "sha256-kBQqTxMIWMCZJA1SuxVb29Y7k+V1Y2qVR2EntoY4FUo=";
  };

  cmakeEntries = {
    REGEX_BACKEND = "pcre2";
    USE_HTTP_PARSER = "llhttp";
    USE_SSH = true;
    USE_GSSAPI = withGssapi;
    BUILD_SHARED_LIBS = !staticBuild;
    ${if stdenv.hostPlatform.isWindows then "DLLTOOL" else null} =
      "${stdenv.cc.bintools.targetPrefix}dlltool";
    # For ws2_32, referred to by a `*.pc` file
    ${if stdenv.hostPlatform.isWindows then "CMAKE_LIBRARY_PATH" else null} = "${stdenv.cc.libc}/lib";
    # openbsd headers fail with default c90
    ${if stdenv.hostPlatform.isOpenBSD then "CMAKE_C_STANDARD" else null} = "99";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
    pkg-config
  ];

  buildInputs = [
    zlib
    libssh2
    openssl
    pcre2
    llhttp
  ]
  ++ lib.optional withGssapi krb5;

  propagatedBuildInputs = lib.optional (!stdenv.hostPlatform.isLinux) libiconv;

  checkPhase = ''
    testArgs=(-v -xonline)

    # slow
    testArgs+=(-xclone::nonetwork::bad_urls)

    # failed to set permissions on ...: Operation not permitted
    testArgs+=(-xrepo::init::extended_1)
    testArgs+=(-xrepo::template::extended_with_template_and_shared_mode)

    (
      set -x
      ./libgit2_tests ''${testArgs[@]}
    )
  '';

  passthru.tests = {
    unittests = runUnitTests finalAttrs.finalPackage;
  }
  // lib.mapAttrs (_: v: v.override { libgit2 = finalAttrs.finalPackage; }) (
    lib.optionalAttrs (libgit2-glib != null) { inherit libgit2-glib; }
    // {
      inherit (python3Packages) pygit2;
    }
    // lib.optionalAttrs (gitstatus != null) { inherit (gitstatus) romkatv_libgit2; }
  );

  meta = {
    description = "Linkable library implementation of Git that you can use in your application";
    mainProgram = "git2";
    homepage = "https://libgit2.org/";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.all;
  };
})
