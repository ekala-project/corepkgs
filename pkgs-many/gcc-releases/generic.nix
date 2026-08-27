{
  majorMinorVersion,
  ...
}:

{
  lib,
  stdenv,
  pkgs,
  overrideCC,
  buildPackages,
  targetPackages,
  callPackage,
  isl,
  noSysDirs,
  wrapCC,
  gccFun,
}:

let
  majorVersion = lib.versions.major majorMinorVersion;
in
lib.lowPrio (
  wrapCC (gccFun {
    inherit noSysDirs;
    inherit majorMinorVersion;
    reproducibleBuild = true;
    profiledCompiler = false;
    libcCross =
      if !lib.systems.equals stdenv.targetPlatform stdenv.buildPlatform then
        targetPackages.libc or pkgs.libc
      else
        null;
    threadsCross = { };
    isl = if stdenv.hostPlatform.isDarwin then null else isl;
    stdenv =
      if
        (
          (!lib.systems.equals stdenv.targetPlatform stdenv.buildPlatform)
          || (!lib.systems.equals stdenv.hostPlatform stdenv.targetPlatform)
        )
        && stdenv.cc.isGNU
      then
        overrideCC stdenv buildPackages."gcc${majorVersion}"
      else
        stdenv;
  })
)
