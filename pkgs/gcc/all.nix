{ lib
, stdenv
, gccStdenv
, gcc7Stdenv
, callPackage
, isl
, libcCross
, threadsCross
, noSysDirs
, lowPrio
, wrapCC
}@args:

let
  versions = import ./versions.nix;
  gccForMajorMinorVersion = majorMinorVersion:
    let
      atLeast = lib.versionAtLeast majorMinorVersion;
      attrName = "gcc${lib.replaceStrings ["."] [""] majorMinorVersion}";
      pkg = lowPrio (wrapCC (callPackage ./default.nix ({
        inherit noSysDirs;
        inherit majorMinorVersion;
        reproducibleBuild = true;
        profiledCompiler = false;
        libcCross = if stdenv.targetPlatform != stdenv.buildPlatform then args.libcCross else null;
        threadsCross = if stdenv.targetPlatform != stdenv.buildPlatform then threadsCross else { };
        isl = if       stdenv.isDarwin then null
              else if    atLeast "9"   then isl.v0_20
              else if    atLeast "7"   then isl.v0_17
              else if    atLeast "6"   then (if stdenv.targetPlatform.isRedox then isl.v0_17 else isl.v0_14)
              else if    atLeast "4.9" then isl.v0_11
              else            /* "4.8" */   isl.v0_14;
      } // lib.optionalAttrs (atLeast "6" && !(atLeast "9")) {
        # gcc 10 is too strict to cross compile gcc <= 8
        stdenv = if (stdenv.targetPlatform != stdenv.buildPlatform) && stdenv.cc.isGNU then gcc7Stdenv else stdenv;
      })));
    in
      lib.nameValuePair attrName pkg;
in
lib.listToAttrs (map gccForMajorMinorVersion versions.allMajorVersions)

