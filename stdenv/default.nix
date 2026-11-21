# This file chooses a sane default stdenv given the system, platform, etc.
#
# Rather than returning a stdenv, this returns a list of functions---one per
# each bootstrapping stage. See `./booter.nix` for exactly what this list should
# contain.

{
  # Args just for stdenvs' usage
  lib,
  # Args to pass on to the pkgset builder, too
  localSystem,
  crossSystem,
  config,
  overlays,
  crossOverlays,
}:

let
  useCrossStdenv = crossSystem != localSystem || crossOverlays != [ ];
  useCustomStdenv = !useCrossStdenv && (config.replaceStdenv or null) != null;

  # Cross and custom stdenvs extend the local bootstrap stages. Keep
  # replaceStdenv out of those stages so it is applied only by the appended
  # custom stage; cross compilation uses replaceCrossStdenv instead.
  bootArgs = {
    inherit lib localSystem overlays;
    config =
      if useCrossStdenv || useCustomStdenv then removeAttrs config [ "replaceStdenv" ] else config;
  };

  # The native (i.e., impure) build environment.  This one uses the
  # tools installed on the system outside of the Nix environment,
  # i.e., the stuff in /bin, /usr/bin, etc.  This environment should
  # be used with care, since many Nix packages will not build properly
  # with it (e.g., because they require GNU Make).
  stagesNative = import ./native bootArgs;

  # The Nix build environment.
  stagesNix = import ./nix (bootArgs // { bootStages = stagesNative; });

  stagesFreeBSD = import ./freebsd bootArgs;

  # On Linux systems, the standard build environment consists of Nix-built
  # instances glibc and the `standard' Unix tools, i.e., the Posix utilities,
  # the GNU C compiler, and so on.
  stagesLinux = import ./linux bootArgs;

  stagesDarwin = import ./darwin bootArgs;

  bootStages =
    if localSystem.isLinux then
      stagesLinux
    else if localSystem.isDarwin then
      stagesDarwin
    else
      {
        x86_64-solaris = stagesNix;
        x86_64-freebsd = stagesFreeBSD;
      }
      .${localSystem.system} or stagesNative;

  # `config.ekacache.enable`: one more native stage, rebuilding the package set
  # with its compilers launched through ekacache's `ec`. `ec` comes from the
  # stage below, so it never has to build itself. Cross and custom stdenvs
  # build on top of this stage, and so are launched too.
  ekacacheStage = vanillaPackages: {
    inherit (bootArgs) config overlays;
    stdenv = vanillaPackages.stdenvAdapters.withEkacache vanillaPackages.ekacache vanillaPackages.stdenv;
  };

  nativeStages = bootStages ++ lib.optional (config.ekacache.enable or false) ekacacheStage;

  stagesCross = import ./cross {
    inherit
      lib
      localSystem
      crossSystem
      config
      overlays
      crossOverlays
      ;
    bootStages = nativeStages;
  };

  replaceStdenvStage = vanillaPackages: {
    inherit config overlays;
    stdenv = config.replaceStdenv { pkgs = vanillaPackages; };
  };

in
if useCrossStdenv then
  stagesCross
else if useCustomStdenv then
  nativeStages ++ [ replaceStdenvStage ]
else
  nativeStages
