# This a top-level overlay which is applied after this "autoCalled" pkgs directory.
# This mainly serves as a way to define attrs at the top-level of pkgs which
# require more than just passing default arguments to nix expressions

final: prev: with final; 
let
  # lib = final.lib;
  # inherit (final) lib;
  # inherit (final.lib) recurseIntoAttrs lowPrio;
in
{
  inherit (lib) recurseIntoAttrs lowPrio;
  # TODO(corepkgs): deprecate lowPrio

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
        # TODO(core-pkgs): support dawrin
        # inherit (buildPackages.darwin) bootstrap_cmds;
        udev = if stdenv.hostPlatform.isLinux then udev else null;
        libdrm = if stdenv.hostPlatform.isLinux then libdrm else null;
      };

      # TODO(core-pkgs): Move xorg's generated to a generated.nix, and move the package set
      # logic into a default.nix
      generatedPackages = lib.callPackageWith __splicedPackages ./pkgs/xorg { };

      xorgPackages = makeScopeWithSplicing' {
        otherSplices = generateSplicesForMkScope "xorg";
        f = lib.extends overrides generatedPackages;
      };

    in
    recurseIntoAttrs xorgPackages;

  unixtools = lib.recurseIntoAttrs (callPackages ./unixtools.nix { });
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
}