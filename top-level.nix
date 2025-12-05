# This a top-level overlay which is applied after this "autoCalled" pkgs directory.
# This mainly serves as a way to define attrs at the top-level of pkgs which
# require more than just passing default arguments to nix expressions

final: prev: with final; {

  # TODO, corepkgs: deprecate lowPrio;
  inherit (final.lib) recurseIntoAttrs lowPrio;

  # Non-GNU/Linux OSes are currently "impure" platforms, with their libc
  # outside of the store.  Thus, GCC, GFortran, & co. must always look for files
  # in standard system directories (/usr/include, etc.)
  noSysDirs =
    stdenv.buildPlatform.system != "x86_64-solaris"
    && stdenv.buildPlatform.system != "x86_64-kfreebsd-gnu";

  mkManyVariants = callFromScope ./pkgs/mkManyVariants { };

  fetchFromGitHub = callFromScope ./pkgs/fetchFromGitHub { };

  stdenvNoCC = stdenv.override (
    {
      cc = null;
      hasCC = false;
    }

    //
      lib.optionalAttrs (stdenv.hostPlatform.isDarwin && (stdenv.hostPlatform != stdenv.buildPlatform))
        {
          # TODO: This is a hack to use stdenvNoCC to produce a CF when cross
          # compiling. It's not very sound. The cross stdenv has:
          #   extraBuildInputs = [ targetPackages.darwin.apple_sdks.frameworks.CoreFoundation ]
          # and uses stdenvNoCC. In order to make this not infinitely recursive, we
          # need to exclude this extraBuildInput.
          extraBuildInputs = [ ];
        }
  );

  # TODO: move output of pkgs scope
  threadsCross =
    lib.optionalAttrs (stdenv.targetPlatform.isMinGW && !(stdenv.targetPlatform.useLLVM or false))
      {
        # other possible values: win32 or posix
        model = "mcf";
        # For win32 or posix set this to null
        package = targetPackages.windows.mcfgthreads or windows.mcfgthreads;
      };

  # TODO: move out of pkgs scope
  wrapBintoolsWith =
    {
      bintools,
      libc ? if stdenv.targetPlatform != stdenv.hostPlatform then libcCross else stdenv.cc.libc,
      ...
    }@extraArgs:
    callPackage ./build-support/bintools-wrapper (
      let
        self = {
          nativeTools = stdenv.targetPlatform == stdenv.hostPlatform && stdenv.cc.nativeTools or false;
          nativeLibc = stdenv.targetPlatform == stdenv.hostPlatform && stdenv.cc.nativeLibc or false;
          nativePrefix = stdenv.cc.nativePrefix or "";

          noLibc = (self.libc == null);

          inherit bintools libc;
        }
        // extraArgs;
      in
      self
    );

  wrapCCWith =
    {
      cc,
      # This should be the only bintools runtime dep with this sort of logic. The
      # Others should instead delegate to the next stage's choice with
      # `targetPackages.stdenv.cc.bintools`. This one is different just to
      # provide the default choice, avoiding infinite recursion.
      # See the bintools attribute for the logic and reasoning. We need to provide
      # a default here, since eval will hit this function when bootstrapping
      # stdenv where the bintools attribute doesn't exist, but will never actually
      # be evaluated -- callPackage ends up being too eager.
      bintools ? pkgs.bintools,
      libc ? bintools.libc,
      # libc++ from the default LLVM version is bound at the top level, but we
      # want the C++ library to be explicitly chosen by the caller, and null by
      # default.
      libcxx ? null,
      extraPackages ? lib.optional (
        cc.isGNU or false && stdenv.targetPlatform.isMinGW
      ) threadsCross.package,
      nixSupport ? { },
      ...
    }@extraArgs:
    callPackage ./build-support/cc-wrapper (
      let
        self = {
          nativeTools = stdenv.targetPlatform == stdenv.hostPlatform && stdenv.cc.nativeTools or false;
          nativeLibc = stdenv.targetPlatform == stdenv.hostPlatform && stdenv.cc.nativeLibc or false;
          nativePrefix = stdenv.cc.nativePrefix or "";
          noLibc = !self.nativeLibc && (self.libc == null);

          isGNU = cc.isGNU or false;
          isClang = cc.isClang or false;
          isArocc = cc.isArocc or false;
          isZig = cc.isZig or false;

          inherit
            cc
            bintools
            libc
            libcxx
            extraPackages
            nixSupport
            zlib
            ;
        }
        // extraArgs;
      in
      self
    );

  wrapCC =
    cc:
    wrapCCWith {
      inherit cc;
    };

  inherit (callPackages ./apparmor { })
    libapparmor
    apparmor-utils
    apparmor-bin-utils
    apparmor-parser
    apparmor-pam
    apparmor-profiles
    apparmor-kernel-patches
    apparmorRulesFromClosure
    ;

  # TODO: use mkManyVariant
  autoconf269 = callPackage ./pkgs/autoconf/269.nix { };

  autoreconfHook269 = autoreconfHook.override {
    autoconf = autoconf269;
  };

  autoPatchelfHook = makeSetupHook {
    name = "auto-patchelf-hook";
    propagatedBuildInputs = [ bintools ];
    substitutions = {
      pythonInterpreter = "${python3.withPackages (ps: [ ps.pyelftools ])}/bin/python";
      autoPatchelfScript = ./build-support/setup-hooks/auto-patchelf.py;
    };
  } ./build-support/setup-hooks/auto-patchelf.sh;

  # TODO: corepkgs, mkManyVariant
  bash = lowPrio (callPackage ./pkgs/bash/5.nix { });
  # WARNING: this attribute is used by nix-shell so it shouldn't be removed/renamed
  bashInteractive = callPackage ./pkgs/bash/5.nix {
    interactive = true;
    withDocs = true;
  };
  bashInteractiveFHS = callPackage ./pkgs/bash/5.nix {
    interactive = true;
    withDocs = true;
    forFHSEnv = true;
  };

  # Here we select the default bintools implementations to be used.  Note when
  # cross compiling these are used not for this stage but the *next* stage.
  # That is why we choose using this stage's target platform / next stage's
  # host platform.
  #
  # Because this is the *next* stages choice, it's a bit non-modular to put
  # here. In theory, bootstraping is supposed to not be a chain but at tree,
  # where each stage supports many "successor" stages, like multiple possible
  # futures. We don't have a better alternative, but with this downside in
  # mind, please be judicious when using this attribute. E.g. for building
  # things in *this* stage you should use probably `stdenv.cc.bintools` (from a
  # default or alternate `stdenv`), at build time, and try not to "force" a
  # specific bintools at runtime at all.
  #
  # In other words, try to only use this in wrappers, and only use those
  # wrappers from the next stage.
  bintools-unwrapped =
    let
      inherit (stdenv.targetPlatform) linker;
    in
    if linker == "lld" then
      llvmPackages.bintools-unwrapped
    else if linker == "cctools" then
      darwin.binutils-unwrapped
    else if linker == "bfd" then
      binutils-unwrapped
    else if linker == "gold" then
      binutils-unwrapped.override { enableGoldDefault = true; }
    else
      null;
  bintoolsNoLibc = wrapBintoolsWith {
    bintools = bintools-unwrapped;
    libc = preLibcCrossHeaders;
  };

  bintools = wrapBintoolsWith {
    bintools = bintools-unwrapped;
  };

  bintoolsDualAs = wrapBintoolsWith {
    bintools = darwin.binutilsDualAs-unwrapped;
    wrapGas = true;
  };

  binutils-unwrapped = callPackage ./pkgs/binutils {
    autoreconfHook = autoreconfHook269;
    inherit (darwin.apple_sdk.frameworks) CoreServices;
    # FHS sys dirs presumably only have stuff for the build platform
    noSysDirs = (stdenv.targetPlatform != stdenv.hostPlatform) || noSysDirs;
  };
  binutils-unwrapped-all-targets = callPackage ./pkgs/binutils {
    autoreconfHook = if targetPlatform.isiOS then autoreconfHook269 else autoreconfHook;
    inherit (darwin.apple_sdk.frameworks) CoreServices;
    # FHS sys dirs presumably only have stuff for the build platform
    noSysDirs = (stdenv.targetPlatform != stdenv.hostPlatform) || noSysDirs;
    withAllTargets = true;
  };
  binutils = wrapBintoolsWith {
    bintools = binutils-unwrapped;
  };
  binutils_nogold = lowPrio (wrapBintoolsWith {
    bintools = binutils-unwrapped.override {
      enableGold = false;
    };
  });
  binutilsNoLibc = wrapBintoolsWith {
    bintools = binutils-unwrapped;
    libc = preLibcCrossHeaders;
  };

  boostPackages = callPackage ./pkgs/boost { };
  inherit (boostPackages)
    boost175
    boost177
    boost178
    boost179
    boost180
    boost181
    boost182
    boost183
    boost184
    boost185
    boost186
    ;
  boost = boost186;

  buildcatrust = with python3.pkgs; toPythonApplication buildcatrust;

  buildEnv = callPackage ./build-support/buildenv { }; # not actually a package

  c-aresMinimal = callPackage ./pkgs/c-ares { withCMake = false; };

  closureInfo = callPackage ./build-support/closure-info.nix { };

  cmakeMinimal = prev.cmake.minimal;

  clang = llvmPackages.clang;
  clang_12 = llvmPackages_12.clang;
  clang_13 = llvmPackages_13.clang;
  clang_14 = llvmPackages_14.clang;
  clang_15 = llvmPackages_15.clang;
  clang_16 = llvmPackages_16.clang;
  clang_17 = llvmPackages_17.clang;

  clang-tools = llvmPackages.clang-tools;

  copyPkgconfigItems = makeSetupHook {
    name = "copy-pkg-config-items-hook";
  } ./build-support/setup-hooks/copy-pkgconfig-items.sh;

  curlMinimal = prev.curl;

  curl = curlMinimal.override (
    {
      idnSupport = true;
      pslSupport = true;
      zstdSupport = true;
    }
    // lib.optionalAttrs (!stdenv.hostPlatform.isStatic) {
      brotliSupport = true;
    }
  );

  # Provided by libc on Operating Systems that use the Extensible Linker Format.
  # TODO: core-pkgs: why is this here?
  elf-header =
    if stdenv.hostPlatform.isElf then
      null
    else
      throw "Non-elf builds are not supported yet in this repo";

  # TODO: core-pkgs: move to build-support
  ensureNewerSourcesHook =
    { year }:
    makeSetupHook
      {
        name = "ensure-newer-sources-hook";
      }
      (
        writeScript "ensure-newer-sources-hook.sh" ''
          postUnpackHooks+=(_ensureNewerSources)
          _ensureNewerSources() {
            local r=$sourceRoot
            # Avoid passing option-looking directory to find. The example is diffoscope-269:
            #   https://salsa.debian.org/reproducible-builds/diffoscope/-/issues/378
            [[ $r == -* ]] && r="./$r"
            '${findutils}/bin/find' "$r" \
              '!' -newermt '${year}-01-01' -exec touch -h -d '${year}-01-02' '{}' '+'
          }
        ''
      );

  # Zip file format only allows times after year 1980, which makes e.g. Python
  # wheel building fail with:
  # ValueError: ZIP does not support timestamps before 1980
  ensureNewerSourcesForZipFilesHook = ensureNewerSourcesHook { year = "1980"; };

  expand-response-params = callPackage ./build-support/expand-response-params { };

  # TODO: support darwin builds
  darwin = {
    autoSignDarwinBinariesHook = null;
    bootstrap_cmds = null;
    signingUtils = null;
    configd = null;
  };

  db_4 = callPackage ./pkgs/db/db-4.8.nix { };
  db_5_3 = callPackage ./pkgs/db/db-5.3.nix { };
  db_5 = db_5_3;
  db = db_5;

  docbook_xml_dtd_412 = callPackage ./pkgs/docbook-xml-dtd/4.1.2.nix { };

  docbook_xml_dtd_42 = callPackage ./pkgs/docbook-xml-dtd/4.2.nix { };

  docbook_xml_dtd_43 = callPackage ./pkgs/docbook-xml-dtd/4.3.nix { };

  docbook_xml_dtd_44 = callPackage ./pkgs/docbook-xml-dtd/4.4.nix { };

  docbook_xml_dtd_45 = callPackage ./pkgs/docbook-xml-dtd/4.5.nix { };

  docbook_xml_ebnf_dtd = callPackage ./pkgs/docbook-xml-dtd/docbook-ebnf { };

  inherit (callPackage ./pkgs/docbook_xsl { })
    docbook-xsl-nons
    docbook-xsl-ns
    ;

  # TODO: move this to aliases
  docbook_xsl = docbook-xsl-nons;
  docbook_xsl_ns = docbook-xsl-ns;

  fetchgit = callFromScope ./build-support/fetchgit { };

  fetchFromGitLab = callPackage ./build-support/fetchgitlab { };

  fetchFromRepoOrCz = callPackage ./build-support/fetchrepoorcz { };

  fetchpatch =
    callPackage ./build-support/fetchpatch {
      # 0.3.4 would change hashes: https://github.com/NixOS/nixpkgs/issues/25154
      patchutils = __splicedPackages.patchutils_0_3_3;
    }
    // {
      tests = pkgs.tests.fetchpatch;
      version = 1;
    };

  fetchpatch2 =
    callPackage ./build-support/fetchpatch {
      patchutils = __splicedPackages.patchutils_0_4_2;
    }
    // {
      tests = pkgs.tests.fetchpatch2;
      version = 2;
    };

  fetchPypi = callPackage ./build-support/fetchpypi { };

  # `fetchurl' downloads a file from the network.
  fetchurl =
    if stdenv.isCross then
      buildPackages.fetchurl # No need to do special overrides twice,
    else
      lib.makeOverridable (import ./build-support/fetchurl) {
        inherit lib stdenvNoCC buildPackages;
        inherit cacert;
        inherit config;
        curl = buildPackages.curlMinimal.override (old: rec {
          # break dependency cycles
          fetchurl = stdenv.fetchurlBoot;
          zlib = buildPackages.zlib.override { fetchurl = stdenv.fetchurlBoot; };
          pkg-config = buildPackages.pkg-config.override (old: {
            pkg-config-unwrapped = old.pkg-config-unwrapped.override {
              inherit fetchurl;
            };
          });
          perl = buildPackages.perl.override {
            inherit zlib;
            fetchurl = stdenv.fetchurlBoot;
          };
          openssl = buildPackages.openssl.override {
            fetchurl = stdenv.fetchurlBoot;
            buildPackages = {
              coreutils = buildPackages.coreutils.override {
                fetchurl = stdenv.fetchurlBoot;
                inherit perl;
                xz = buildPackages.xz.override { fetchurl = stdenv.fetchurlBoot; };
                gmpSupport = false;
                aclSupport = false;
                attrSupport = false;
              };
              inherit perl;
            };
            inherit perl;
          };
          libssh2 = buildPackages.libssh2.override {
            fetchurl = stdenv.fetchurlBoot;
            inherit zlib openssl;
          };
          # On darwin, libkrb5 needs bootstrap_cmds which would require
          # converting many packages to fetchurl_boot to avoid evaluation cycles.
          # So turn gssSupport off there, and on Windows.
          # On other platforms, keep the previous value.
          gssSupport =
            if stdenv.isDarwin || stdenv.hostPlatform.isWindows then false else old.gssSupport or true; # `? true` is the default
          libkrb5 = buildPackages.libkrb5.override {
            fetchurl = stdenv.fetchurlBoot;
            inherit pkg-config perl openssl;
            keyutils = buildPackages.keyutils.override { fetchurl = stdenv.fetchurlBoot; };
          };
          nghttp2 = buildPackages.nghttp2.override {
            fetchurl = stdenv.fetchurlBoot;
            inherit pkg-config;
            enableApp = false; # curl just needs libnghttp2
            enableTests = false; # avoids bringing `cunit` and `tzdata` into scope
          };
        });
      };

  fetchzip = callPackage ./build-support/fetchzip { } // {
    tests = pkgs.tests.fetchzip;
  };

  findXMLCatalogs = makeSetupHook {
    name = "find-xml-catalogs-hook";
  } ./build-support/setup-hooks/find-xml-catalogs.sh;

  # TODO: core-pkgs: darwin support
  fixDarwinDylibNames = null;

  # TODO: core-pkgs: freebsd support
  freebsd = { };

  # TODO: core-pkgs: make less ugly
  fusePackages = prev.fuse;
  fuse_2 = prev.fuse.fuse_2;
  fuse_3 = prev.fuse.fuse_3;
  fuse = prev.fuse.fuse_3;

  # TODO: Move this into an "updaters.*" package set
  genericUpdater = prev.generic-updater;

  # TODO: don't use a top-level defined attr to define this
  inherit (callPackage ./pkgs/gcc/all.nix { })
    gcc6
    gcc7
    gcc8
    gcc9
    gcc10
    gcc11
    gcc12
    gcc13
    gcc14
    ;

  gcc_latest = gcc14;

  default-gcc-version = if (with stdenv.targetPlatform; isVc4 || libc == "relibc") then 6 else 13;
  gcc = pkgs.${"gcc${toString default-gcc-version}"};
  gccFun = callPackage ./gcc;
  gcc-unwrapped = gcc.cc;

  gccStdenv =
    if stdenv.cc.isGNU then
      stdenv
    else
      stdenv.override {
        cc = buildPackages.gcc;
        allowedRequisites = null;
        # Remove libcxx/libcxxabi, and add clang for AS if on darwin (it uses
        # clang's internal assembler).
        extraBuildInputs = lib.optional stdenv.hostPlatform.isDarwin clang.cc;
      };

  gcc6Stdenv = overrideCC gccStdenv buildPackages.gcc6;
  gcc7Stdenv = overrideCC gccStdenv buildPackages.gcc7;
  gcc8Stdenv = overrideCC gccStdenv buildPackages.gcc8;
  gcc9Stdenv = overrideCC gccStdenv buildPackages.gcc9;
  gcc10Stdenv = overrideCC gccStdenv buildPackages.gcc10;
  gcc11Stdenv = overrideCC gccStdenv buildPackages.gcc11;
  gcc12Stdenv = overrideCC gccStdenv buildPackages.gcc12;
  gcc13Stdenv = overrideCC gccStdenv buildPackages.gcc13;
  gcc14Stdenv = overrideCC gccStdenv buildPackages.gcc14;

  gitUpdater = prev.git-updater;
  unstableGitUpdater = callPackage ./common-updater/unstable-updater.nix { };

  ghostscript_headless = ghostscript.override {
    cupsSupport = false;
    x11Support = false;
  };

  git = callPackage ./pkgs/git {
    perlLibs = [
      perlPackages.LWP
      perlPackages.URI
      perlPackages.TermReadKey
    ];
    smtpPerlLibs = [
      perlPackages.libnet
      perlPackages.NetSMTPSSL
      perlPackages.IOSocketSSL
      perlPackages.NetSSLeay
      perlPackages.AuthenSASL
      perlPackages.DigestHMAC
    ];
  };

  # The full-featured Git.
  gitFull = git.override {
    svnSupport = true;
    guiSupport = true;
    sendEmailSupport = true;
    withSsh = true;
    withLibsecret = !stdenv.isDarwin;
  };

  glib = callPackage ./pkgs/glib (
    let
      glib-untested = glib.overrideAttrs { doCheck = false; };
    in
    {
      # break dependency cycles
      # these things are only used for tests, they don't get into the closure
      shared-mime-info = shared-mime-info.override { glib = glib-untested; };
      desktop-file-utils = desktop-file-utils.override { glib = glib-untested; };
      dbus = dbus.override { enableSystemd = false; };
    }
  );

  glibcLocales = callPackage ./pkgs/glibc/locales.nix { };
  glibcLocalesUtf8 = glibcLocales.override { allLocales = false; };

  # TODO: mkManyVariant
  gmp4 = callPackage ./pkgs/gmp/4.3.2.nix { }; # required by older GHC versions
  gmp5 = callPackage ./pkgs/gmp/5.1.x.nix { };
  gmp6 = callPackage ./pkgs/gmp/6.x.nix { };
  gmp = gmp6;
  gmpxx = gmp.override { cxx = true; };

  # TODO: core-pkgs: determine if gnome pkgset should go in core or "pkgs"
  # If it shouldn't be in core, move gnome.update-script to this repo
  gnome = { };

  gobject-introspection-unwrapped = callPackage ./pkgs/gobject-introspection/unwrapped.nix { };

  gpm_ncurses = gpm.override { withNcurses = true; };

  grpc = null;

  icu-versions = callPackage ./pkgs/icu { };
  icu = icu-versions.icu74;

  installShellFiles = callPackage ./build-support/install-shell-files { };

  openjdk21 = javaPackages.compiler.openjdk21;
  jdk21 = openjdk21;
  jdk = jdk21;

  # We can choose:
  libcCrossChooser =
    name:
    # libc is hackily often used from the previous stage. This `or`
    # hack fixes the hack, *sigh*.
    if name == null then
      null
    else if name == "glibc" then
      targetPackages.glibcCross or glibcCross
    else if name == "bionic" then
      targetPackages.bionic or bionic
    else if name == "uclibc" then
      targetPackages.uclibcCross or uclibcCross
    else if name == "avrlibc" then
      targetPackages.avrlibcCross or avrlibcCross
    else if name == "newlib" && stdenv.targetPlatform.isMsp430 then
      targetPackages.msp430NewlibCross or msp430NewlibCross
    else if name == "newlib" && stdenv.targetPlatform.isVc4 then
      targetPackages.vc4-newlib or vc4-newlib
    else if name == "newlib" && stdenv.targetPlatform.isOr1k then
      targetPackages.or1k-newlib or or1k-newlib
    else if name == "newlib" then
      targetPackages.newlibCross or newlibCross
    else if name == "newlib-nano" then
      targetPackages.newlib-nanoCross or newlib-nanoCross
    else if name == "musl" then
      targetPackages.muslCross or muslCross
    else if name == "msvcrt" then
      targetPackages.windows.mingw_w64 or windows.mingw_w64
    else if name == "ucrt" then
      targetPackages.windows.mingw_w64 or windows.mingw_w64
    else if name == "libSystem" then
      if stdenv.targetPlatform.useiOSPrebuilt then
        targetPackages.darwin.iosSdkPkgs.libraries or darwin.iosSdkPkgs.libraries
      else
        targetPackages.darwin.LibsystemCross
          or (throw "don't yet have a `targetPackages.darwin.LibsystemCross for ${stdenv.targetPlatform.config}`")
    else if name == "fblibc" then
      targetPackages.freebsd.libc or freebsd.libc
    else if name == "oblibc" then
      targetPackages.openbsd.libc or openbsd.libc
    else if name == "nblibc" then
      targetPackages.netbsd.libc or netbsd.libc
    else if name == "wasilibc" then
      targetPackages.wasilibc or wasilibc
    else if name == "relibc" then
      targetPackages.relibc or relibc
    else
      throw "Unknown libc ${name}";

  libcCross =
    assert stdenv.targetPlatform != stdenv.buildPlatform;
    libcCrossChooser stdenv.targetPlatform.libc;

  # TODO: mkManyVariant
  libffi_3_3 = callPackage ./libffi/3.3.nix { };
  libffiBoot = libffi.override {
    doCheck = false;
  };

  libgcc = stdenv.cc.cc.libgcc or null;

  inherit (callPackages ./os-specific/linux/kernel-headers { inherit (pkgsBuildBuild) elf-header; })
    linuxHeaders
    makeLinuxHeaders
    ;

  # TODO: core-pkgs: move openGL into it's own file
  ## libGL/libGLU/Mesa stuff

  # Default libGL implementation.
  #
  # Android NDK provides an OpenGL implementation, we can just use that.
  #
  # On macOS, we use the OpenGL framework. Packages that still need GLX
  # specifically can pull in libGLX instead. If you have a package that
  # should work without X11 but it can’t find the library, it may help
  # to add the path to `NIX_CFLAGS_COMPILE`:
  #
  #     -L${libGL}/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries
  #
  # If you still can’t get it working, please don’t hesitate to ping
  # @NixOS/darwin-maintainers to ask an expert to take a look.
  libGL =
    if stdenv.hostPlatform.useAndroidPrebuilt then
      stdenv
    else if stdenv.hostPlatform.isDarwin then
      darwin.apple_sdk.frameworks.OpenGL
    else
      libglvnd;

  # On macOS, we use the OpenGL framework. Packages that use libGLX on
  # macOS may need to depend on mesa_glu directly if this doesn’t work.
  libGLU = if stdenv.hostPlatform.isDarwin then darwin.apple_sdk.frameworks.OpenGL else mesa_glu;

  # libglvnd does not work (yet?) on macOS.
  libGLX = if stdenv.hostPlatform.isDarwin then mesa else libglvnd;

  # On macOS, we use the GLUT framework. Packages that use libGLX on
  # macOS may need to depend on freeglut directly if this doesn’t work.
  libglut = if stdenv.hostPlatform.isDarwin then darwin.apple_sdk.frameworks.GLUT else freeglut;

  # TODO: core-pkg: Add darwin support
  # mesa = if stdenv.isDarwin
  #   then darwin.apple_sdk_11_0.callPackage ../development/libraries/mesa/darwin.nix {
  #     inherit (darwin.apple_sdk_11_0.libs) Xplugin;
  #   }
  #   else callPackage ../development/libraries/mesa {};

  libcap_ng = callPackage ./os-specific/linux/libcap-ng { };

  # TODO: fix this
  libkrb5 = prev.krb5.override { type = "lib"; };

  libsoup_3 = callPackage ./pkgs/libsoup/3.x.nix { };

  # TODO: corepkgs: gross
  libtool = callPackage ./pkgs/libtool/libtool2.nix { };
  libtool_1 = callPackage ./pkgs/libtool { };

  # TODO: core-pkgs: just replace usages with util-linuxMinimal?
  libuuid = if stdenv.isLinux then util-linuxMinimal else null;

  linux-pam = pam;

  # TODO: core-pkgs: cleanup llvm aliases packageSets
  lld = llvmPackages.lld;
  lld_12 = llvmPackages_12.lld;
  lld_13 = llvmPackages_13.lld;
  lld_14 = llvmPackages_14.lld;
  lld_15 = llvmPackages_15.lld;
  lld_16 = llvmPackages_16.lld;
  lld_17 = llvmPackages_17.lld;

  lldb = llvmPackages.lldb;
  lldb_12 = llvmPackages_12.lldb;
  lldb_13 = llvmPackages_13.lldb;
  lldb_14 = llvmPackages_14.lldb;
  lldb_15 = llvmPackages_15.lldb;
  lldb_16 = llvmPackages_16.lldb;
  lldb_17 = llvmPackages_17.lldb;

  llvm = llvmPackages.llvm;
  llvm_12 = llvmPackages_12.llvm;
  llvm_13 = llvmPackages_13.llvm;
  llvm_14 = llvmPackages_14.llvm;
  llvm_15 = llvmPackages_15.llvm;
  llvm_16 = llvmPackages_16.llvm;
  llvm_17 = llvmPackages_17.llvm;

  mlir_16 = llvmPackages_16.mlir;
  mlir_17 = llvmPackages_17.mlir;

  libllvm = llvmPackages.libllvm;
  llvm-manpages = llvmPackages.llvm-manpages;

  llvmPackages =
    let
      # This returns the minimum supported version for the platform. The
      # assumption is that or any later version is good.
      choose =
        platform:
        if platform.isDarwin then
          16
        else if platform.isFreeBSD then
          18
        else if platform.isOpenBSD then
          18
        else if platform.isAndroid then
          12
        else if platform.isLinux then
          18
        else if platform.isWasm then
          16
        # For unknown systems, assume the latest version is required.
        else
          18;
      # We take the "max of the mins". Why? Since those are lower bounds of the
      # supported version set, this is like intersecting those sets and then
      # taking the min bound of that.
      minSupported = toString (
        lib.trivial.max (choose stdenv.hostPlatform) (choose stdenv.targetPlatform)
      );
    in
    pkgs.${"llvmPackages_${minSupported}"};

  llvmPackages_12 = recurseIntoAttrs (
    callPackage ./pkgs/llvm/12 ({
      inherit (stdenvAdapters) overrideCC;
      buildLlvmTools = buildPackages.llvmPackages_12.tools;
      targetLlvmLibraries = targetPackages.llvmPackages_12.libraries or llvmPackages_12.libraries;
      targetLlvm = targetPackages.llvmPackages_12.llvm or llvmPackages_12.llvm;
    })
  );

  inherit
    (rec {
      llvmPackagesSet = recurseIntoAttrs (callPackages ./pkgs/llvm { });

      llvmPackages_13 = llvmPackagesSet."13";
      llvmPackages_14 = llvmPackagesSet."14";
      llvmPackages_15 = llvmPackagesSet."15";
      llvmPackages_16 = llvmPackagesSet."16";
      llvmPackages_17 = llvmPackagesSet."17";

      llvmPackages_18 = llvmPackagesSet."18";
      clang_18 = llvmPackages_18.clang;
      lld_18 = llvmPackages_18.lld;
      lldb_18 = llvmPackages_18.lldb;
      llvm_18 = llvmPackages_18.llvm;

      llvmPackages_19 = llvmPackagesSet."19";
      clang_19 = llvmPackages_19.clang;
      lld_19 = llvmPackages_19.lld;
      lldb_19 = llvmPackages_19.lldb;
      llvm_19 = llvmPackages_19.llvm;
      bolt_19 = llvmPackages_19.bolt;
    })
    llvmPackages_13
    llvmPackages_14
    llvmPackages_15
    llvmPackages_16
    llvmPackages_17
    llvmPackages_18
    clang_18
    lld_18
    lldb_18
    llvm_18
    llvmPackages_19
    clang_19
    lld_19
    lldb_19
    llvm_19
    bolt_19
    ;

  m4 = gnum4;

  makeBinaryWrapper = callPackage ./build-support/setup-hooks/make-binary-wrapper { };

  makeFontsConf = callPackage ./build-support/make-fonts-conf { };

  makePkgconfigItem = callPackage ./build-support/make-pkgconfigitem { };

  memstreamHook = makeSetupHook {
    name = "memstream-hook";
    propagatedBuildInputs = [ memstream ];
  } ./pkgs/memstream/setup-hook.sh;

  mpi = openmpi;

  # TODO: support NixOS tests
  nixosTests = { };

  # TODO: Create ekapkgs specific version
  nix-update-script = { };

  opensshPackages = dontRecurseIntoAttrs (callPackage ./pkgs/openssh { });

  openssh = opensshPackages.openssh.override {
    etcDir = "/etc/ssh";
  };

  opensshTest = openssh.tests.openssh;

  opensshWithKerberos = openssh.override {
    withKerberos = true;
  };

  openssh_hpn = opensshPackages.openssh_hpn.override {
    etcDir = "/etc/ssh";
  };

  openssh_hpnWithKerberos = openssh_hpn.override {
    withKerberos = true;
  };

  openssh_gssapi = opensshPackages.openssh_gssapi.override {
    etcDir = "/etc/ssh";
    withKerberos = true;
  };

  openssl = openssl_3;
  inherit (callPackages ./pkgs/openssl { })
    openssl_1_1
    openssl_3
    openssl_3_2
    openssl_3_3
    ;

  patch = gnupatch;
  patchutils_0_3_3 = callPackage ./pkgs/patchutils/0.3.3.nix { };

  patchutils_0_4_2 = callPackage ./pkgs/patchutils/0.4.2.nix { };

  perlInterpreters = callPackage ./pkgs/perl { };
  perl = perlInterpreters.perl538;

  perlPackages = perl.pkgs;

  pkg-config = callPackage ./build-support/pkg-config-wrapper { };

  # These are used when buiding compiler-rt / libgcc, prior to building libc.
  preLibcCrossHeaders =
    let
      inherit (stdenv.targetPlatform) libc;
    in
    if stdenv.targetPlatform.isMinGW then
      targetPackages.windows.mingw_w64_headers or windows.mingw_w64_headers
    else if libc == "nblibc" then
      targetPackages.netbsd.headers or netbsd.headers
    else if libc == "libSystem" && stdenv.targetPlatform.isAarch64 then
      targetPackages.darwin.LibsystemCross or darwin.LibsystemCross
    else
      null;

  procps =
    if stdenv.isLinux then
      callPackage ./os-specific/linux/procps-ng { }
    else
      throw "non-linux procps is not supported yet";

  inherit (callPackage ./python { })
    python310
    python311
    python312
    python3Minimal
    pypy
    ;
  python = python3;
  python3 = python311;
  python3Packages = recurseIntoAttrs python3.pkgs;

  readline = readline_8_2;
  readline_7_0 = callPackage ./pkgs/readline/7.0.nix { };
  readline_8_2 = callPackage ./pkgs/readline/8.2.nix { };

  removeReferencesTo = callPackage ./build-support/remove-references-to {
    inherit (darwin) signingUtils;
  };

  inherit (callPackage ./pkgs/ruby { })
    mkRubyVersion
    mkRuby
    ruby_3_1
    ruby_3_2
    ruby_3_3
    ;

  ruby = ruby_3_3;
  rubyPackages = rubyPackages_3_3;

  rubyPackages_3_1 = recurseIntoAttrs ruby_3_1.gems;
  rubyPackages_3_2 = recurseIntoAttrs ruby_3_2.gems;
  rubyPackages_3_3 = recurseIntoAttrs ruby_3_3.gems;

  runtimeShell = "${runtimeShellPackage}${runtimeShellPackage.shellPath}";
  runtimeShellPackage = bash;

  rust_1_91 = callPackage ./pkgs/rust/1_91.nix { };
  rust = rust_1_91;

  rustPackages_1_91 = rust_1_91.packages.stable;
  rustPackages = rustPackages_1_91;

  inherit (rustPackages)
    cargo
    cargo-auditable
    cargo-auditable-cargo-wrapper
    clippy
    rustc
    rustPlatform
    ;

  makeRustPlatform = callPackage ./pkgs/rust/make-rust-platform.nix { };

  wrapRustcWith = { rustc-unwrapped, ... }@args: callPackage ./build-support/rust/rustc-wrapper args;
  wrapRustc = rustc-unwrapped: wrapRustcWith { inherit rustc-unwrapped; };

  separateDebugInfo = makeSetupHook {
    name = "separate-debug-info-hook";
  } ./build-support/setup-hooks/separate-debug-info.sh;

  setupDebugInfoDirs = makeSetupHook {
    name = "setup-debug-info-dirs-hook";
  } ./build-support/setup-hooks/setup-debug-info-dirs.sh;

  shortenPerlShebang = makeSetupHook {
    name = "shorten-perl-shebang-hook";
    propagatedBuildInputs = [ dieHook ];
  } ./build-support/setup-hooks/shorten-perl-shebang.sh;

  sphinx = with python3Packages; toPythonApplication sphinx;

  substitute = callPackage ./build-support/substitute/substitute.nix { };

  substituteAll = callPackage ./build-support/substitute/substitute-all.nix { };

  substituteAllFiles = callPackage ./build-support/substitute-files/substitute-all-files.nix { };

  swig_3 = prev.swig;
  swig_4 = callPackage ./pkgs/swig/4.nix { };

  inherit (texlive.schemes)
    texliveBasic
    texliveBookPub
    texliveConTeXt
    texliveFull
    texliveGUST
    texliveInfraOnly
    texliveMedium
    texliveMinimal
    texliveSmall
    texliveTeTeX
    ;
  texlivePackages = recurseIntoAttrs (lib.mapAttrs (_: v: v.build) texlive.pkgs);

  # TODO: corepkgs, mkManyVariant
  texinfoVersions = callPackage ./pkgs/texinfo/packages.nix { };
  texinfo = texinfoVersions.texinfo7;

  tcl = tcl_8_6;
  tcl_8_6 = callPackage ./pkgs/tcl/8.6.nix { };
  tcl_8_5 = callPackage ./pkgs/tcl/8.5.nix { };

  tests = callPackage ./test { };
  # TODO: corepkgs, bring back
  testers = null;

  tk = tcl_8_6;
  tk_8_6 = callPackage ./pkgs/tk/8.6.nix { };
  tk_8_5 = callPackage ./pkgs/tk/8.5.nix { tcl = tcl_8_5; };

  # GNU libc provides libiconv so systems with glibc don't need to
  # build libiconv separately. Additionally, Apple forked/repackaged
  # libiconv, so build and use the upstream one with a compatible ABI,
  # and BSDs include libiconv in libc.
  #
  # We also provide `libiconvReal`, which will always be a standalone libiconv,
  # just in case you want it regardless of platform.
  libiconv =
    if
      lib.elem stdenv.hostPlatform.libc [
        "glibc"
        "musl"
        "nblibc"
        "wasilibc"
        "fblibc"
      ]
    then
      libcIconv (if stdenv.hostPlatform != stdenv.buildPlatform then libcCross else stdenv.cc.libc)
    else if stdenv.hostPlatform.isDarwin then
      libiconv-darwin
    else
      libiconvReal;

  libcIconv =
    libc:
    let
      inherit (libc) pname version;
      libcDev = lib.getDev libc;
    in
    runCommand "${pname}-iconv-${version}" { strictDeps = true; } ''
      mkdir -p $out/include
      ln -sv ${libcDev}/include/iconv.h $out/include
    '';

  libiconvReal = callPackage ../development/libraries/libiconv { };

  iconv =
    if
      lib.elem stdenv.hostPlatform.libc [
        "glibc"
        "musl"
      ]
    then
      lib.getBin stdenv.cc.libc
    else if stdenv.hostPlatform.isDarwin then
      lib.getBin libiconv
    else if stdenv.hostPlatform.isFreeBSD then
      lib.getBin freebsd.iconv
    else
      lib.getBin libiconvReal;

  # On non-GNU systems we need GNU Gettext for libintl.
  libintl = if stdenv.hostPlatform.libc != "glibc" then gettext else null;

  libxcrypt = prev.libxcrypt.override {
    # Prevent infinite recursion
    fetchurl = stdenv.fetchurlBoot;
    perl = buildPackages.perl.override {
      enableCrypt = false;
      fetchurl = stdenv.fetchurlBoot;
    };
  };

  update-python-libraries = callPackage ./python/update-python-libraries { };

  util-linuxMinimal = util-linux.override {
    nlsSupport = false;
    ncursesSupport = false;
    systemdSupport = false;
    translateManpages = false;
  };

  xorg =
    let
      # Use `lib.callPackageWith __splicedPackages` rather than plain `callPackage`
      # so as not to have the newly bound xorg items already in scope,  which would
      # have created a cycle.
      overrides = lib.callPackageWith __splicedPackages ./pkgs/xorg/overrides.nix {
        # TODO: core-pkgs: support dawrin
        # inherit (darwin.apple_sdk.frameworks) ApplicationServices Carbon Cocoa;
        # inherit (darwin.apple_sdk.libs) Xplugin;
        # inherit (buildPackages.darwin) bootstrap_cmds;
        udev = if stdenv.isLinux then udev else null;
        libdrm = if stdenv.isLinux then libdrm else null;
      };

      # TODO: core-pkgs: Move xorg's generated to a generated.nix, and move the package set
      # logic into a default.nix
      generatedPackages = lib.callPackageWith __splicedPackages ./pkgs/xorg { };

      xorgPackages = makeScopeWithSplicing' {
        otherSplices = generateSplicesForMkScope "xorg";
        f = lib.extends overrides generatedPackages;
      };

    in
    recurseIntoAttrs xorgPackages;

  inherit (xorg)
    libX11
    xorgproto
    ;

  # Unix tools
  unixtools = recurseIntoAttrs (callPackages ./unixtools.nix { });
  inherit (unixtools)
    hexdump
    ps
    logger
    eject
    umount
    mount
    wall
    hostname
    more
    sysctl
    getconf
    getent
    locale
    killall
    xxd
    watch
    ;

  # TODO: core-pkgs: darwin support
  xcbuild = null;
  xcodebuild = null;

  # Support windows
  windows = {
    mingw_w64 = null;
  };
}
