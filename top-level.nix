# This a top-level overlay which is applied after this "autoCalled" pkgs directory.
# This mainly serves as a way to define attrs at the top-level of pkgs which
# require more than just passing default arguments to nix expressions

final: prev:
let
  # TODO(corepkgs): deprecate lowPrio
  inherit (final.lib) lowPrio;
in
with final; {
   # TODO(corepkgs): support NixOS tests
  nixosTests = { };
  tests = { };

  # TODO(corepkgs): Create ekapkg specific version
  nix-update-script = { };
  nix-update = null;

  # TODO(corepkgs): support darwin builds
  darwin = {
    autoSignDarwinBinariesHook = null;
    bootstrap_cmds = null;
    signingUtils = null;
    configd = null;
  };
  bootstrap_cmds = null;
  apple-sdk = null;
  windows = null;

  # Non-GNU/Linux OSes are currently "impure" platforms, with their libc
  # outside of the store.  Thus, GCC, GFortran, & co. must always look for files
  # in standard system directories (/usr/include, etc.)
  # TODO(corepkgs): move into stdenv/linux.nix
  noSysDirs =
    stdenv.buildPlatform.system != "x86_64-solaris"
    && stdenv.buildPlatform.system != "x86_64-kfreebsd-gnu";

  mkManyVariants = callFromScope ./pkgs/mkManyVariants { };

  # A stdenv capable of building 32-bit binaries.
  # On x86_64-linux, it uses GCC compiled with multilib support; on i686-linux,
  # it's just the plain stdenv.
  stdenv_32bit = lowPrio (if stdenv.hostPlatform.is32bit then stdenv else multiStdenv);

  mkStdenvNoLibs =
    stdenv:
    let
      bintools = stdenv.cc.bintools.override {
        libc = null;
        noLibc = true;
      };
    in
    stdenv.override {
      cc = stdenv.cc.override {
        libc = null;
        noLibc = true;
        extraPackages = [ ];
        inherit bintools;
      };
      allowedRequisites = lib.mapNullable (rs: rs ++ [ bintools ]) (stdenv.allowedRequisites or null);
    };

  stdenvNoLibs =
    if stdenvNoCC.hostPlatform != stdenvNoCC.buildPlatform then
      # We cannot touch binutils or cc themselves, because that will cause
      # infinite recursion. So instead, we just choose a libc based on the
      # current platform. That means we won't respect whatever compiler was
      # passed in with the stdenv stage argument.
      #
      # TODO It would be much better to pass the `stdenvNoCC` and *unwrapped*
      # cc, bintools, compiler-rt equivalent, etc. and create all final stdenvs
      # as part of the stage. Then we would never be tempted to override a later
      # thing to to create an earlier thing (leading to infinite recursion) and
      # we also would still respect the stage arguments choices for these
      # things.
      (
        if stdenvNoCC.hostPlatform.isDarwin || stdenvNoCC.hostPlatform.useLLVM or false then
          overrideCC stdenvNoCC buildPackages.llvmPackages.clangNoCompilerRt
        else
          gccCrossLibcStdenv
      )
    else
      mkStdenvNoLibs stdenv;

    stdenvNoLibc =
    if stdenvNoCC.hostPlatform != stdenvNoCC.buildPlatform then
      (
        if stdenvNoCC.hostPlatform.isDarwin || stdenvNoCC.hostPlatform.useLLVM or false then
          overrideCC stdenvNoCC buildPackages.llvmPackages.clangNoLibc
        else
          gccCrossLibcStdenv
      )
    else
      mkStdenvNoLibs stdenv;

  gccStdenvNoLibs = mkStdenvNoLibs gccStdenv;
  clangStdenvNoLibs = mkStdenvNoLibs clangStdenv;

  glibc = callPackage ./pkgs/glibc (
    if stdenv.hostPlatform != stdenv.buildPlatform then
      {
        stdenv = gccCrossLibcStdenv; # doesn't compile without gcc
        # TODO(corepkgs): this is duplication of pkgs/gcc/common/libgcc.nix
        libgcc = callPackage ./pkgs/glibc/libgcc-for-glibc.nix {
          gcc = gccCrossLibcStdenv.cc;
          glibc = glibc.override { libgcc = null; };
          stdenvNoLibs = gccCrossLibcStdenv;
        };
      }
    else
      {
        stdenv = gccStdenv; # doesn't compile without gcc
      }
  );

  # Only supported on Linux and only on glibc
  glibcLocales =
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isGnu then
      callPackage ./pkgs/glibc/locales.nix {
        stdenv = if (!stdenv.cc.isGNU) then gccStdenv else stdenv;
        withLinuxHeaders = !stdenv.cc.isGNU;
      }
    else
      null;
  glibcLocalesUtf8 =
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isGnu then
      callPackage ./pkgs/glibc/locales.nix {
        stdenv = if (!stdenv.cc.isGNU) then gccStdenv else stdenv;
        withLinuxHeaders = !stdenv.cc.isGNU;
        allLocales = false;
      }
    else
      null;

  glibcInfo = callPackage ./pkgs/glibc/info.nix { };

  glibc_multi = callPackage ./pkgs/glibc/multi.nix {
    # The buildPackages is required for cross-compilation. The pkgsi686Linux set
    # has target and host always set to the same value based on target platform
    # of the current set. We need host to be same as build to correctly get i686
    # variant of glibc.
    glibc32 = pkgsi686Linux.buildPackages.glibc;
  };

   libc = let
        inherit (stdenv.hostPlatform) libc;
        # libc is hackily often used from the previous stage. This `or`
        # hack fixes the hack, *sigh*.
      in
      if libc == null then
        null
      else if libc == "glibc" then
        glibc
      else if libc == "bionic" then
        bionic
      else if libc == "uclibc" then
        uclibc
      else if libc == "avrlibc" then
        avrlibc
      else if libc == "newlib" && stdenv.hostPlatform.isMsp430 then
        msp430Newlib
      else if libc == "newlib" && stdenv.hostPlatform.isVc4 then
        vc4-newlib
      else if libc == "newlib" && stdenv.hostPlatform.isOr1k then
        or1k-newlib
      else if libc == "newlib" then
        newlib
      else if libc == "newlib-nano" then
        newlib-nano
      else if libc == "musl" then
        musl
      else if libc == "msvcrt" then
        windows.mingw_w64
      else if libc == "ucrt" then
        windows.mingw_w64
      else if libc == "libSystem" then
        if stdenv.hostPlatform.useiOSPrebuilt then darwin.iosSdkPkgs.libraries else darwin.libSystem
      else if libc == "fblibc" then
        freebsd.libc
      else if libc == "oblibc" then
        openbsd.libc
      else if libc == "nblibc" then
        netbsd.libc
      else if libc == "wasilibc" then
        wasilibc
      else if libc == "relibc" then
        relibc
      else if name == "llvm" then
        llvmPackages_20.libc
      else
        throw "Unknown libc ${libc}";

  binutils-unwrapped = callPackage ./pkgs/binutils {
    # FHS sys dirs presumably only have stuff for the build platform
    noSysDirs = (stdenv.targetPlatform != stdenv.hostPlatform) || noSysDirs;
  };
  binutils-unwrapped-all-targets = callPackage ./pkgs/binutils {
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
    libc = targetPackages.preLibcHeaders or preLibcHeaders;
  };

  libbfd = callPackage ./pkgs/binutils/libbfd.nix { };

  libopcodes = callPackage ./pkgs/binutils/libopcodes.nix { };

  # Held back 2.38 release. Remove once all dependencies are ported to 2.39.
  binutils-unwrapped_2_38 = callPackage ./pkgs/binutils/2.38 {
    autoreconfHook = autoreconfHook269;
    # FHS sys dirs presumably only have stuff for the build platform
    noSysDirs = (stdenv.targetPlatform != stdenv.hostPlatform) || noSysDirs;
  };

  libbfd_2_38 = callPackage ./pkgs/binutils/2.38/libbfd.nix {
    autoreconfHook = buildPackages.autoreconfHook269;
  };

  libopcodes_2_38 = callPackage ./pkgs/binutils/2.38/libopcodes.nix {
    autoreconfHook = buildPackages.autoreconfHook269;
  };

  # Here we select the default bintools implementations to be used.  Note when
  # cross compiling these are used not for this stage but the *next* stage.
  # That is why we choose using this stage's target platform / next stage's
  # host platform.
  #
  # Because this is the *next* stages choice, it's a bit non-modular to put
  # here. In theory, bootstrapping is supposed to not be a chain but at tree,
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
    libc = targetPackages.preLibcHeaders or preLibcHeaders;
  };
  bintools = wrapBintoolsWith {
    bintools = bintools-unwrapped;
  };

  bintoolsDualAs = wrapBintoolsWith {
    bintools = darwin.binutilsDualAs-unwrapped;
    wrapGas = true;
  };

  xorg =
    let
      # Use `lib.callPackageWith __splicedPackages` rather than plain `callPackage`
      # so as not to have the newly bound xorg items already in scope,  which would
      # have created a cycle.
      overrides = lib.callPackageWith __splicedPackages ./pkgs/xorg/overrides.nix {
        # TODO(corepkgs): support dawrin
        # inherit (buildPackages.darwin) bootstrap_cmds;
        udev = if stdenv.hostPlatform.isLinux then udev else null;
        libdrm = if stdenv.hostPlatform.isLinux then libdrm else null;
      };

      # TODO(corepkgs): Move xorg's generated to a generated.nix, and move the package set
      # logic into a default.nix
      generatedPackages = lib.callPackageWith __splicedPackages ./pkgs/xorg { };

      xorgPackages = makeScopeWithSplicing' {
        otherSplices = generateSplicesForMkScope "xorg";
        f = lib.extends overrides generatedPackages;
      };

    in
    lib.recurseIntoAttrs xorgPackages;

    inherit (xorg)
    xorgproto
    ;

  # TODO(corepkgs): use mkManyVariants
  autoconf = callPackage ./pkgs/autoconf { };
  autoconf269 = callPackage ./pkgs/autoconf/2.69.nix { };
  autoconf271 = callPackage ./pkgs/autoconf/2.71.nix { };

  # TODO(corepkgs): use mkManyVariants
  automake = automake118x;
  automake116x = callPackage ./pkgs/automake/automake-1.16.x.nix { };
  automake118x = callPackage ./pkgs/automake/automake-1.18.x.nix { };

  # TODO(corepkgs): use mkManyVariants
  autoreconfHook269 = autoreconfHook.override { autoconf = autoconf269; };
  autoreconfHook271 = autoreconfHook.override { autoconf = autoconf271; };

  dbus = callPackage ./pkgs/dbus { };
  makeDBusConf = callPackage ./pkgs/dbus/make-dbus-conf.nix { };

  # TODO(corepkgs): move these fetchers into pkgs
  fetchpatch = callPackage ./build-support/fetchpatch {
      # 0.3.4 would change hashes: https://github.com/NixOS/nixpkgs/issues/25154
      patchutils = __splicedPackages.patchutils_0_3_3;
      }
      // {
      tests = pkgs.tests.fetchpatch;
      version = 1;
    };
  fetchpatch2 = callPackage ../build-support/fetchpatch {
      patchutils = __splicedPackages.patchutils_0_4_2;
      }
      // {
      tests = pkgs.tests.fetchpatch2;
      version = 2;
    };
  fetchgit = callFromScope ./build-support/fetchgit { };
  fetchgitLocal = callPackage ./build-support/fetchgitlocal { };
  fetchFromGitLab = callPackage ./build-support/fetchgitlab { };
  # TODO(corepkgs): uppercase them?
  fetchzip = callPackage ./build-support/fetchzip { };
  fetchurl =
    if stdenv.buildPlatform != stdenv.hostPlatform then
      buildPackages.fetchurl # No need to do special overrides twice,
    else
      lib.makeOverridable (import ./build-support/fetchurl) {
        inherit lib stdenvNoCC buildPackages cacert config;
        curl = buildPackages.curlMinimal.override (old: rec {
          # break dependency cycles
          fetchurl = stdenv.fetchurlBoot;
          zlib = buildPackages.zlib.override { fetchurl = stdenv.fetchurlBoot; };
          pkg-config = buildPackages.pkg-config.override (old: {
            pkg-config = old.pkg-config.override {
              fetchurl = stdenv.fetchurlBoot;
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
            if stdenv.hostPlatform.isDarwin || stdenv.hostPlatform.isWindows then
              false
            else
              old.gssSupport or true; # `? true` is the default
          libkrb5 = buildPackages.krb5.override {
            fetchurl = stdenv.fetchurlBoot;
            inherit pkg-config perl openssl;
            withLibedit = false;
            byacc = buildPackages.byacc.override { fetchurl = stdenv.fetchurlBoot; };
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
  
  # Default libGL implementation.
  #
  # Android NDK provides an OpenGL implementation, we can just use that.
  #
  # On macOS, the SDK provides the OpenGL framework in `stdenv`.
  # Packages that still need GLX specifically can pull in `libGLX`
  # instead. If you have a package that should work without X11 but it
  # can’t find the library, it may help to add the path to
  # `$NIX_CFLAGS_COMPILE`:
  #
  #    preConfigure = ''
  #      export NIX_CFLAGS_COMPILE+=" -L$SDKROOT/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
  #    '';
  #
  libGL =
    if stdenv.hostPlatform.useAndroidPrebuilt then
      stdenv
    else if stdenv.hostPlatform.isDarwin then
      null
    else
      libglvnd;

  # On macOS, the SDK provides the OpenGL framework in `stdenv`.
  # Packages that use `libGLX` on macOS may need to depend on
  # `mesa_glu` directly if this doesn’t work.
  libGLU = if stdenv.hostPlatform.isDarwin then null else mesa_glu;

  # `libglvnd` does not work (yet?) on macOS.
  libGLX = if stdenv.hostPlatform.isDarwin then mesa else libglvnd;

  # On macOS, the SDK provides the GLUT framework in `stdenv`. Packages
  # that use `libGLX` on macOS may need to depend on `freeglut`
  # directly if this doesn’t work.
  libglut = if stdenv.hostPlatform.isDarwin then null else freeglut;
  mesa =
    if stdenv.hostPlatform.isDarwin then
      callPackage ./pkgs/mesa/darwin.nix { }
    else
      callPackage ./pkgs/mesa { };
  mesa_i686 = pkgsi686Linux.mesa; # make it build on Hydra
  libgbm = callPackage ./pkgs/mesa/gbm.nix { };
  mesa-gl-headers = callPackage ./pkgs/mesa/headers.nix { };

   libunwind =
    # Use the system unwinder in the SDK but provide a compatibility package to:
    # 1. avoid evaluation errors with setting `unwind` to `null`; and
    # 2. provide a `.pc` for compatibility with packages that expect to find libunwind that way.
    if stdenv.hostPlatform.isDarwin then
      darwin.libunwind
    else if stdenv.hostPlatform.system == "riscv32-linux" then
      llvmPackages.libunwind
    else
      callPackage ./pkgs/libunwind { };

  # TODO(corepkgs): remove legacy
  libxcrypt-legacy = libxcrypt.override { enableHashes = "all"; };
  libxcrypt = callPackage ./pkgs/libxcrypt {
    fetchurl = stdenv.fetchurlBoot;
    perl = buildPackages.perl.override {
      enableCrypt = false;
      fetchurl = stdenv.fetchurlBoot;
    };
  };

  # TODO(corepkgs): gross
  libtool = libtool2;
  libtool2 = callPackage ./pkgs/libtool/libtool2.nix { };
  libtool_1_5 = callPackage ./pkgs/libtool { };

  patchelf = callPackage ./pkgs/patchelf { };
  patchelfUnstable = lowPrio (callPackage ./pkgs/patchelf/unstable.nix { });

  default-gcc-version = 14;
  gcc = pkgs.${"gcc${toString default-gcc-version}"};
  gccFun = callPackage ./pkgs/gcc { };
  gcc-unwrapped = gcc.cc;
  libgcc = stdenv.cc.cc.libgcc or null;

  # This is for e.g. LLVM libraries on linux.
  gccForLibs =
    if
      stdenv.targetPlatform == stdenv.hostPlatform && targetPackages.stdenv.cc.isGNU
    # Can only do this is in the native case, otherwise we might get infinite
    # recursion if `targetPackages.stdenv.cc.cc` itself uses `gccForLibs`.
    then
      targetPackages.stdenv.cc.cc
    else
      gcc.cc;

   inherit
    (rec {
      # NOTE: keep this with the "NG" label until we're ready to drop the monolithic GCC
      gccNGPackagesSet = recurseIntoAttrs (callPackages ./pkgs/gcc/ng { });
      gccNGPackages_15 = gccNGPackagesSet."15";
      mkGCCNGPackages = gccNGPackagesSet.mkPackage;
    })
    gccNGPackages_15
    mkGCCNGPackages
    ;

  wrapNonDeterministicGcc =
    stdenv: ccWrapper:
    if ccWrapper.isGNU then
      ccWrapper.overrideAttrs (old: {
        env = old.env // {
          cc = old.env.cc.override {
            reproducibleBuild = false;
            profiledCompiler = with stdenv; (!isDarwin && hostPlatform.isx86);
          };
        };
      })
    else
      ccWrapper;

  gnuStdenv =
    if stdenv.cc.isGNU then
      stdenv
    else
      gccStdenv.override {
        cc = gccStdenv.cc.override {
          bintools = buildPackages.binutils;
        };
      };

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

  gcc13Stdenv = overrideCC gccStdenv buildPackages.gcc13;
  gcc14Stdenv = overrideCC gccStdenv buildPackages.gcc14;
  gcc15Stdenv = overrideCC gccStdenv buildPackages.gcc15;

  # This is not intended for use in nixpkgs but for providing a faster-running
  # compiler to nixpkgs users by building gcc with reproducibility-breaking
  # profile-guided optimizations
  fastStdenv = overrideCC gccStdenv (wrapNonDeterministicGcc gccStdenv buildPackages.gcc_latest);

  wrapCCMulti =
    cc:
    let
      # Binutils with glibc multi
      bintools = cc.bintools.override {
        libc = glibc_multi;
      };
    in
    lowPrio (wrapCCWith {
      cc = cc.cc.override {
        stdenv = overrideCC stdenv (wrapCCWith {
          cc = cc.cc;
          inherit bintools;
          libc = glibc_multi;
        });
        profiledCompiler = false;
        enableMultilib = true;
      };
      libc = glibc_multi;
      inherit bintools;
      extraBuildCommands = ''
        echo "dontMoveLib64=1" >> $out/nix-support/setup-hook
      '';
    });

  wrapClangMulti =
    clang:
    callPackage ../development/compilers/llvm/multi.nix {
      inherit clang;
      gcc32 = pkgsi686Linux.gcc;
      gcc64 = pkgs.gcc;
    };

  gcc_multi = wrapCCMulti gcc;
  clang_multi = wrapClangMulti clang;

  gccMultiStdenv = overrideCC stdenv buildPackages.gcc_multi;
  clangMultiStdenv = overrideCC stdenv buildPackages.clang_multi;
  multiStdenv = if stdenv.cc.isClang then clangMultiStdenv else gccMultiStdenv;

  gcc_debug = lowPrio (
    wrapCC (
      gcc.cc.overrideAttrs {
        dontStrip = true;
      }
    )
  );

  gccCrossLibcStdenv = overrideCC stdenvNoCC buildPackages.gccWithoutTargetLibc;

  # The GCC used to build libc for the target platform. Normal gccs will be
  # built with, and use, that cross-compiled libc.
  gccWithoutTargetLibc =
    let
      libc1 = binutilsNoLibc.libc;
    in
    (wrapCCWith {
      cc = gccFun {
        # copy-pasted
        inherit noSysDirs;
        majorMinorVersion = toString default-gcc-version;

        reproducibleBuild = true;
        profiledCompiler = false;

        isl = if !stdenv.hostPlatform.isDarwin then isl_0_20 else null;

        withoutTargetLibc = true;
        langCC = stdenv.targetPlatform.isCygwin; # can't compile libcygwin1.a without C++
        libcCross = libc1;
        targetPackages.stdenv.cc.bintools = binutilsNoLibc;
        enableShared =
          stdenv.targetPlatform.hasSharedLibraries

          # temporarily disabled due to breakage;
          # see https://github.com/NixOS/nixpkgs/pull/243249
          && !stdenv.targetPlatform.isWindows
          && !stdenv.targetPlatform.isCygwin
          && !(stdenv.targetPlatform.useLLVM or false);
      };
      bintools = binutilsNoLibc;
      libc = libc1;
      extraPackages = [ ];
    }).overrideAttrs
      (prevAttrs: {
        meta = prevAttrs.meta // {
          badPlatforms =
            (prevAttrs.meta.badPlatforms or [ ])
            ++ lib.optionals (stdenv.targetPlatform == stdenv.hostPlatform) [ stdenv.hostPlatform.system ];
        };
      });

  # TODO(corepkgs): use mkManyVariants
  inherit (callPackage ./pkgs/gcc/all.nix { inherit noSysDirs; })
    gcc13
    gcc14
    gcc15
    ;

  gcc_latest = gcc15;

  libgccjit = gcc.cc.override {
    name = "libgccjit";
    langFortran = false;
    langCC = false;
    langC = false;
    profiledCompiler = false;
    langJit = true;
    enableLTO = false;
  };

  # TODO(corepkgs): use mkManyVariants
  inherit
    (rec {
      isl = isl_0_20;
      isl_0_20 = callPackage ./pkgs/isl/0.20.0.nix { };
      isl_0_23 = callPackage ./pkgs/isl/0.23.0.nix { };
      isl_0_27 = callPackage ./pkgs/isl/0.27.0.nix { };
    })
    isl
    isl_0_20
    isl_0_23
    isl_0_27
    ;

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
      ) targetPackages.threads.package,
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
            lib
            cc
            bintools
            libc
            libcxx
            extraPackages
            nixSupport
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
  wrapBintoolsWith =
    {
      bintools,
      libc ? targetPackages.libc or pkgs.libc,
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
  removeReferencesTo = callPackage ./build-support/remove-references-to { };
  replaceVarsWith = callPackage ./build-support/replace-vars/replace-vars-with.nix { };
  replaceVars = callPackage ./build-support/replace-vars/replace-vars.nix { };
  replaceDirectDependencies = callPackage ./build-support/replace-direct-dependencies.nix { };

  runtimeShell = "${runtimeShellPackage}${runtimeShellPackage.shellPath}";
  runtimeShellPackage = bashNonInteractive;
  bash = callPackage ./pkgs/bash/5.nix { };
  bashNonInteractive = lowPrio (
    callPackage ./pkgs/bash/5.nix {
      interactive = false;
    }
  );
  # WARNING: this attribute is used by nix-shell so it shouldn't be removed/renamed
  bashInteractive = bash;
  bashFHS = callPackage ./pkgs/bash/5.nix {
    forFHSEnv = true;
  };
  bashInteractiveFHS = bashFHS;

  # TODO(corepkgs): use mkManyVariants
  flex_2_5_35 = callPackage ./pkgs/flex/2.5.35.nix { };
  flex = callPackage ./pkgs/flex { };

  # Python interpreters. All standard library modules are included except for tkinter, which is
  # available as `pythonPackages.tkinter` and can be used as any other Python package.
  python = python3;
  python2 = python27;
  python3 = python313;

  # pythonPackages further below, but assigned here because they need to be in sync
  python2Packages = dontRecurseIntoAttrs python27Packages;
  python3Packages = dontRecurseIntoAttrs python313Packages;

  pypy = pypy2;
  pypy2 = pypy27;
  pypy3 = pypy311;

  # Python interpreter that is build with all modules, including tkinter.
  # These are for compatibility and should not be used inside Nixpkgs.
  python2Full = python2.override {
    self = python2Full;
    pythonAttr = "python2Full";
    x11Support = true;
  };
  python27Full = python27.override {
    self = python27Full;
    pythonAttr = "python27Full";
    x11Support = true;
  };

  # https://py-free-threading.github.io
  python313FreeThreading = python313.override {
    self = python313FreeThreading;
    pythonAttr = "python313FreeThreading";
    enableGIL = false;
  };
  python314FreeThreading = python314.override {
    self = python314FreeThreading;
    pythonAttr = "python314FreeThreading";
    enableGIL = false;
  };
  python315FreeThreading = python315.override {
    self = python315FreeThreading;
    pythonAttr = "python315FreeThreading";
    enableGIL = false;
  };

  pythonInterpreters = callPackage ./pkgs/python { inherit config; };
  inherit (pythonInterpreters)
    python27
    python310
    python311
    python312
    python313
    python314
    python315
    python3Minimal
    pypy27
    pypy310
    pypy311
    ;

  # List of extensions with overrides to apply to all Python package sets.
  pythonPackagesExtensions = [ ] ;

  # Python package sets.
  python27Packages = python27.pkgs;
  python310Packages = python310.pkgs;
  python311Packages = python311.pkgs;
  python312Packages = recurseIntoAttrs python312.pkgs;
  python313Packages = recurseIntoAttrs python313.pkgs;
  python314Packages = python314.pkgs;
  python315Packages = python315.pkgs;
  pypyPackages = pypy.pkgs;
  pypy2Packages = pypy2.pkgs;
  pypy27Packages = pypy27.pkgs;
  pypy3Packages = pypy3.pkgs;
  pypy310Packages = pypy310.pkgs;
  pypy311Packages = pypy311.pkgs;

  pythonManylinuxPackages = callPackage ./pkgs/python/manylinux { };

  pythonCondaPackages = callPackage ./pkgs/python/conda { };

  # Should eventually be moved inside Python interpreters.
  python-setup-hook = buildPackages.callPackage ./pkgs/python/setup-hook.nix { };

  pythonDocs = recurseIntoAttrs (callPackage ./pkgs/python/cpython/docs { });

  # Provided by libc on Operating Systems that use the Extensible Linker Format.
  elf-header = if stdenv.hostPlatform.isElf then null else elf-header-real;

  inherit (callPackages ./os-specific/linux/kernel-headers { inherit (pkgsBuildBuild) elf-header; })
    linuxHeaders
    makeLinuxHeaders
    ;

  # TODO(corepkgs): use mkManyVariants
  gmp6 = callPackage ./pkgs/gmp/6.x.nix { };
  gmp = gmp6;
  gmpxx = gmp.override { cxx = true; };

  # TODO(corepkgs): alias?
  m4 = gnum4;

  coreutils = callPackage ./pkgs/coreutils { };

  # The coreutils above is built with dependencies from
  # bootstrapping. We cannot override it here, because that pulls in
  # openssl from the previous stage as well.
  coreutils-full = callPackage ./pkgs/coreutils { minimal = false; };
  coreutils-prefixed = coreutils.override {
    withPrefix = true;
    singleBinary = false;
  };

  # GNU libc provides libiconv so systems with glibc don't need to
  # build libiconv separately. Additionally, Apple forked/repackaged
  # libiconv, so build and use the upstream one with a compatible ABI,
  # and BSDs include libiconv in libc.
  #
  # We also provide `libiconvReal`, which will always be a standalone libiconv,
  # just in case you want it regardless of platform.
  # TODO(corepkgs): use mkManyVariants
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
      libcIconv pkgs.libc
    else if stdenv.hostPlatform.isDarwin then
      darwin.libiconv
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

  libiconvReal = callPackage ./pkgs/libiconv { };

  iconv =
    if
      lib.elem stdenv.hostPlatform.libc [
        "glibc"
        "musl"
      ]
    then
      lib.getBin libc
    else if stdenv.hostPlatform.isDarwin then
      lib.getBin libiconv
    else if stdenv.hostPlatform.isFreeBSD then
      lib.getBin freebsd.iconv
    else
      lib.getBin libiconvReal;

  # TODO(corepkgs): use mkManyVariants
  openssl = openssl_3_6;
  openssl_oqs = openssl.override {
    providers = [
      {
        name = "oqsprovider";
        package = pkgs.oqs-provider;
      }
    ];
    autoloadProviders = true;

    extraINIConfig = {
      tls_system_default = {
        Groups = "X25519MLKEM768:X25519:P-256:X448:P-521:ffdhe2048:ffdhe3072";
      };
    };
  };
  openssl_legacy = openssl.override {
    conf = ./pkgs/openssl/3.0/legacy.cnf;
  };
  inherit (callPackages ./pkgs/openssl { })
    openssl_1_1
    openssl_3
    openssl_3_6
    ;

  # TODO(corepkgs): move build-support hooks into pkgs
  makeWrapper = makeShellWrapper;
  makeShellWrapper = makeSetupHook {
    name = "make-shell-wrapper-hook";
    propagatedBuildInputs = [ dieHook ];
    substitutions = {
      # targetPackages.runtimeShell only exists when pkgs == targetPackages (when targetPackages is not  __raw)
      shell =
        if targetPackages ? runtimeShell then
          targetPackages.runtimeShell
        else
          throw "makeWrapper/makeShellWrapper must be in nativeBuildInputs";
    };
    passthru = {
      tests = tests.makeWrapper;
    };
  } ./build-support/setup-hooks/make-wrapper.sh;
  __flattenIncludeHackHook = callPackage ./build-support/setup-hooks/flatten-include-hack { };
  dieHook = makeSetupHook {
    name = "die-hook";
  } ./build-support/setup-hooks/die.sh;
  findXMLCatalogs = makeSetupHook {
    name = "find-xml-catalogs-hook";
  } ./build-support/setup-hooks/find-xml-catalogs.sh;
  arrayUtilities =
    let
      arrayUtilitiesPackages = makeScopeWithSplicing' {
        otherSplices = generateSplicesForMkScope "arrayUtilities";
        f =
          finalArrayUtilities:
          {
            callPackages = lib.callPackagesWith (pkgs // finalArrayUtilities);
          }
          // lib.packagesFromDirectoryRecursive {
            inherit (finalArrayUtilities) callPackage;
            directory = ./build-support/setup-hooks/arrayUtilities;
          };
      };
    in
    recurseIntoAttrs arrayUtilitiesPackages;
  addBinToPathHook = callPackage (
    { makeSetupHook }:
    makeSetupHook {
      name = "add-bin-to-path-hook";
    } ./build-support/setup-hooks/add-bin-to-path.sh
  ) { };
  autoPatchelfHook = makeSetupHook {
    name = "auto-patchelf-hook";
    propagatedBuildInputs = [
      auto-patchelf
      bintools
    ];
    substitutions = {
      hostPlatform = stdenv.hostPlatform.config;
    };
  } ./build-support/setup-hooks/auto-patchelf.sh;

   stripJavaArchivesHook = makeSetupHook {
    name = "strip-java-archives-hook";
    propagatedBuildInputs = [ strip-nondeterminism ];
  } ./build-support/setup-hooks/strip-java-archives.sh;

  updateAutotoolsGnuConfigScriptsHook = makeSetupHook {
    name = "update-autotools-gnu-config-scripts-hook";
    substitutions = {
      gnu_config = gnu-config;
    };
  } ./build-support/setup-hooks/update-autotools-gnu-config-scripts.sh;

  testers = callPackage ./build-support/testers { };

  readline70 = callPackage ./pkgs/readline/7.0.nix { };
  readline = callPackage ./pkgs/readline/8.3.nix { };

  util-linuxMinimal = util-linux.override {
    fetchurl = stdenv.fetchurlBoot;
    cryptsetupSupport = false;
    nlsSupport = false;
    ncursesSupport = false;
    pamSupport = false;
    shadowSupport = false;
    systemdSupport = false;
    translateManpages = false;
    withLastlog = false;
  };

  # TODO(corepkgs): use mkManyVariants, move to perl
  perlInterpreters = callPackage ./pkgs/perl { inherit config; };
  inherit (perlInterpreters) perl538 perl540;
  perl538Packages = recurseIntoAttrs perl538.pkgs;
  perl540Packages = recurseIntoAttrs perl540.pkgs;
  perl = perl540;
  perlPackages = perl540Packages;

  # TODO(corepkgs): use mkManyVariants
  texinfoPackages = callPackages ./pkgs/texinfo/packages.nix {
    inherit freebsd gawk libintl ncurses procps;
   };
  inherit (texinfoPackages)
    texinfo6
    texinfo7
    ;
  texinfo = texinfo7;
  texinfoInteractive = texinfo.override { interactive = true; };

  # On non-GNU systems we need GNU Gettext for libintl.
  libintl = if stdenv.hostPlatform.libc != "glibc" then gettext else null;

  # TODO(corepkgs): cleanup and move into pkgs
  common-updater-scripts = callPackage ./common-updater/scripts.nix { };
  genericUpdater = callPackage ./common-updater/generic-updater.nix { };
  _experimental-update-script-combinators = callPackage ./common-updater/combinators.nix { };
  directoryListingUpdater = callPackage ./common-updater/directory-listing-updater.nix { };
  gitUpdater = callPackage ./common-updater/git-updater.nix { };
  httpTwoLevelsUpdater = callPackage ./common-updater/http-two-levels-updater.nix { };
  unstableGitUpdater = callPackage ./common-updater/unstable-updater.nix { };

  # Make bdb5 the default as it is the last release under the custom
  # bsd-like license
  # TODO(corepkgs): use mkManyVariants
  db = db5;
  db4 = db48;
  db48 = callPackage ./pkgs/db/db-4.8.nix { };
  db5 = db53;
  db53 = callPackage ./pkgs/db/db-5.3.nix { };
  db6 = db60;
  db60 = callPackage ./pkgs/db/db-6.0.nix { };
  db62 = callPackage ./pkgs/db/db-6.2.nix { };

  bzip2 = callPackage ./pkgs/bzip2 { };
  bzip2_1_1 = callPackage ./pkgs/bzip2/1_1.nix { };

  # Use Apple’s fork of libffi by default, which provides APIs and trampoline functionality that is not yet
  # merged upstream. This is needed by some packages (such as cffi).
  #
  # `libffiReal` is provided in case the upstream libffi package is needed on Darwin instead of the fork.
  libffiReal = callPackage ./pkgs/libffi { };
  libffi = if stdenv.hostPlatform.isDarwin then darwin.libffi else libffiReal;
  libffi_3_3 = callPackage ./pkgs/libffi/3.3.nix { };

  libuuid = if stdenv.hostPlatform.isLinux then util-linuxMinimal else null;

  # TODO(corepkgs): use mkManyVariants
  ncurses5 = ncurses.override { abiVersion = "5"; };
  ncurses6 = ncurses.override { abiVersion = "6"; };
  ncurses =
    if stdenv.hostPlatform.useiOSPrebuilt then
      null
    else
      callPackage ./pkgs/ncurses {
        # ncurses is included in the SDK. Avoid an infinite recursion by using a bootstrap stdenv.
        stdenv = if stdenv.hostPlatform.isDarwin then darwin.bootstrapStdenv else stdenv;
      };

  pkgconf = callPackage ./build-support/pkg-config-wrapper {
    pkg-config = pkgconf-unwrapped;
    baseBinName = "pkgconf";
  };
  pkg-config = callPackage ./build-support/pkg-config-wrapper {
    pkg-config = pkg-config-unwrapped;
  };
  pkg-configUpstream = lowPrio (
    pkg-config.override (old: {
      pkg-config = old.pkg-config.override {
        vanilla = true;
      };
    })
  );

  sqlite = lowPrio (callPackage ./pkgs/sqlite { });
  inherit
    (callPackage ./pkgs/sqlite/tools.nix {
    })
    sqlite-analyzer
    sqldiff
    sqlite-rsync
    ;
  sqlar = callPackage ./pkgs/sqlite/sqlar.nix { };
  sqlite-interactive = (sqlite.override { interactive = true; }).bin;

  gawk-with-extensions = callPackage ./pkgs/gawk/gawk-with-extensions.nix {
    extensions = gawkextlib.full;
  };
  gawkextlib = callPackage ./pkgs/gawk/gawkextlib.nix { };
  gawkInteractive = gawk.override { interactive = true; };

  # TODO(corepkgs): alias?
  patch = gnupatch;

  # TODO(corepkgs): use mkManyVariants
  tcl = tcl-8_6;
  tcl-8_5 = callPackage ./pkgs/tcl/8.5.nix { };
  tcl-8_6 = callPackage ./pkgs/tcl/8.6.nix { };
  tcl-9_0 = callPackage ./pkgs/tcl/9.0.nix { };
  # We don't need versioned package sets thanks to the tcl stubs mechanism
  tclPackages = recurseIntoAttrs (callPackage ./pkgs/tcl/packages.nix { });

  # TODO(corepkgs): use mkManyVariants
  tk = tk-8_6;
  tk-9_0 = callPackage ./pkgs/tk/9.0.nix { tcl = tcl-9_0; };
  tk-8_6 = callPackage ./pkgs/tk/8.6.nix { };
  tk-8_5 = callPackage ./pkgs/tk/8.5.nix { tcl = tcl-8_5; };

  gpm-ncurses = gpm.override { withNcurses = true; };

  pam =
    if stdenv.hostPlatform.isLinux then
      linux-pam
    else if stdenv.hostPlatform.isFreeBSD then
      freebsd.libpam
    else
      openpam;

  # TODO(corepkgs): alias?
  su = shadow;

  systemd = callPackage ./os-specific/linux/systemd {
    # break some cyclic dependencies
    util-linux = util-linuxMinimal;
    # provide a super minimal gnupg used for systemd-machined
    gnupg = gnupg.override {
      enableMinimal = true;
      guiSupport = false;
    };
  };
  systemdMinimal = systemd.override {
    pname = "systemd-minimal";
    withAcl = false;
    withAnalyze = false;
    withApparmor = false;
    withAudit = false;
    withCompression = false;
    withCoredump = false;
    withCryptsetup = false;
    withRepart = false;
    withDocumentation = false;
    withEfi = false;
    withFido2 = false;
    withGcrypt = false;
    withHostnamed = false;
    withHomed = false;
    withHwdb = false;
    withImportd = false;
    withLibBPF = false;
    withLibidn2 = false;
    withLocaled = false;
    withLogind = false;
    withMachined = false;
    withNetworkd = false;
    withNss = false;
    withOomd = false;
    withOpenSSL = false;
    withPCRE2 = false;
    withPam = false;
    withPolkit = false;
    withPortabled = false;
    withRemote = false;
    withResolved = false;
    withShellCompletions = false;
    withSysupdate = false;
    withSysusers = false;
    withTimedated = false;
    withTimesyncd = false;
    withTpm2Tss = false;
    withUserDb = false;
    withUkify = false;
    withBootloader = false;
    withPasswordQuality = false;
    withVmspawn = false;
    withQrencode = false;
    withLibarchive = false;
    withVConsole = false;
    # withKmod = false; # breaks udevCheckHook of bcache-tools
    withFirstboot = false;
    withKexectools = false;
    withLibseccomp = false;
    withNspawn = false;
  };
  systemdLibs = systemdMinimal.override {
    pname = "systemd-minimal-libs";
    buildLibsOnly = true;
  };
  # We do not want to include ukify in the normal systemd attribute as it
  # relies on Python at runtime.
  systemdUkify = systemd.override {
    withUkify = true;
  };
  udev = if lib.meta.availableOn stdenv.hostPlatform systemdLibs then systemdLibs else libudev-zero;

  inherit (callPackages ./pkgs/docbook-xsl { })
    docbook_xsl
    docbook_xsl_ns
    ;

  inherit (callPackage ./pkgs/libxml2 { })
    libxml2_13
    libxml2
    ;

  # Should always be the version with the most features
  w3m-full = w3m;
  # Version without X11
  w3m-nox = w3m.override {
    x11Support = false;
    imlib2 = imlib2-nox;
  };
  # Version without X11 or graphics
  w3m-nographics = w3m.override {
    x11Support = false;
    graphicsSupport = false;
  };
  # Version for batch text processing, not a good browser
  w3m-batch = w3m.override {
    graphicsSupport = false;
    mouseSupport = false;
    x11Support = false;
    imlib2 = imlib2-nox;
  };

  curlMinimal = prev.curl;
  curl = curlMinimal.override (
   {
      idnSupport = true;
      pslSupport = true;
      zstdSupport = true;
      http3Support = true;
      c-aresSupport = true;
    }
    // lib.optionalAttrs (!stdenv.hostPlatform.isStatic) {
      brotliSupport = true;
    }
  );

  c-aresMinimal = callPackage ./pkgs/c-ares { withCMake = false; };

  libkrb5 = krb5; # TODO(de11n) Try to make krb5 reuse libkrb5 as a dependency

  ngtcp2-gnutls = callPackage ./pkgs/ngtcp2/gnutls.nix { };

  patchutils_0_3_3 = callPackage ./pkgs/patchutils/0.3.3.nix { };
  patchutils_0_4_2 = callPackage ./pkgs/patchutils/0.4.2.nix { };

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
    svnSupport = stdenv.buildPlatform == stdenv.hostPlatform;
    guiSupport = true;
    sendEmailSupport = stdenv.buildPlatform == stdenv.hostPlatform;
    withSsh = true;
    withLibsecret = !stdenv.hostPlatform.isDarwin;
  };

  git-doc = lib.addMetaAttrs {
    description = "Additional documentation for Git";
    longDescription = ''
      This package contains additional documentation (HTML and text files) that
      is referenced in the man pages of Git.
    '';
  } gitFull.doc;

  gitMinimal = git.override {
    withManual = false;
    osxkeychainSupport = false;
    pythonSupport = false;
    perlSupport = false;
    withpcre2 = false;
  };

  deterministic-host-uname = deterministic-uname.override {
    forPlatform = stdenv.targetPlatform; # offset by 1 so it works in nativeBuildInputs
  };

  makeFontsConf = callPackage ./build-support/make-fonts-conf { };
  makeFontsCache = callPackage ./build-support/make-fonts-cache { };

    # can't use override - it triggers infinite recursion
  cmakeMinimal = callPackage ./pkgs/cmake/package.nix {
    isMinimalBuild = true;
  };
  cmakeCurses = cmake.override {
    uiToolkits = [ "ncurses" ];
  };
  cmakeWithGui = cmake.override {
    uiToolkits = [
      "ncurses"
      "qt5"
    ];
  };

  gtk3 = callPackage ./pkgs/gtk/3.x.nix { };
  gtk4 = callPackage ./pkgs/gtk/4.x.nix { };

  buildcatrust = with python3.pkgs; toPythonApplication buildcatrust;

  # unixtools = lib.recurseIntoAttrs (callPackages ./unixtools.nix { });
  # inherit (unixtools)
  #   hexdump
  #   ps
  #   logger
  #   eject
  #   umount
  #   mount
  #   wall
  #   hostname
  #   more
  #   sysctl
  #   getconf
  #   getent
  #   locale
  #   killall
  #   xxd
  #   watch
  #   ;
}