# This a top-level overlay which is applied after this "autoCalled" pkgs directory.
# This mainly serves as a way to define attrs at the top-level of pkgs which
# require more than just passing default arguments to nix expressions

final: prev:
let 
  # TODO(corepkgs): deprecate lowPrio
  inherit (final.lib) recurseIntoAttrs lowPrio;
in
 with final; {

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

  # gccStdenvNoLibs = mkStdenvNoLibs gccStdenv;
  # clangStdenvNoLibs = mkStdenvNoLibs clangStdenv;

  #   bintools-unwrapped =
  #   let
  #     inherit (stdenv.targetPlatform) linker;
  #   in
  #   if linker == "lld" then
  #     llvmPackages.bintools-unwrapped
  #   else if linker == "cctools" then
  #     darwin.binutils-unwrapped
  #   else if linker == "bfd" then
  #     binutils-unwrapped
  #   else if linker == "gold" then
  #     binutils-unwrapped.override { enableGoldDefault = true; }
  #   else
  #     null;
  # bintoolsNoLibc = wrapBintoolsWith {
  #   bintools = bintools-unwrapped;
  #   libc = preLibcCrossHeaders;
  # };

  # bintools = wrapBintoolsWith {
  #   bintools = bintools-unwrapped;
  # };

  # bintoolsDualAs = wrapBintoolsWith {
  #   bintools = darwin.binutilsDualAs-unwrapped;
  #   wrapGas = true;
  # };

  # minimal-bootstrap = recurseIntoAttrs (
  #   import ./os-specific/linux/minimal-bootstrap {
  #     inherit (stdenv) buildPlatform hostPlatform;
  #     inherit lib config;
  #     fetchurl = import ./build-support/fetchurl/boot.nix {
  #       inherit (stdenv.buildPlatform) system;
  #       inherit (config) rewriteURL;
  #     };
  #     checkMeta = callPackage ./stdenv/generic/check-meta.nix { inherit (stdenv) hostPlatform; };
  #   }
  # );
  # minimal-bootstrap-sources =
  #   callPackage ./os-specific/linux/minimal-bootstrap/stage0-posix/bootstrap-sources.nix
  #     {
  #       inherit (stdenv) hostPlatform;
  #     };
  # make-minimal-bootstrap-sources =
  #   callPackage ./os-specific/linux/minimal-bootstrap/stage0-posix/make-bootstrap-sources.nix
  #     {
  #       inherit (stdenv) hostPlatform;
  #     };

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
}