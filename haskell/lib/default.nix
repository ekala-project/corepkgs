# Public API for haskell.lib
# Ported from nixpkgs pkgs/development/haskell-modules/lib/default.nix
#
# The traditional API has the derivation as the first parameter.
# haskell.lib.compose (preferred) has it as the last parameter.
{ pkgs, lib }:

rec {
  compose = import ./compose.nix { inherit pkgs lib; };

  makePackageSet = compose.makePackageSet;

  overrideCabal = drv: f: compose.overrideCabal f drv;

  packageSourceOverrides = compose.packageSourceOverrides;

  doCoverage = compose.doCoverage;
  dontCoverage = compose.dontCoverage;

  doHaddock = compose.doHaddock;
  dontHaddock = compose.dontHaddock;

  doJailbreak = compose.doJailbreak;
  dontJailbreak = compose.dontJailbreak;

  doCheck = compose.doCheck;
  dontCheck = compose.dontCheck;
  dontCheckIf = drv: condition: compose.dontCheckIf condition drv;

  doBenchmark = compose.doBenchmark;
  dontBenchmark = compose.dontBenchmark;

  doDistribute = compose.doDistribute;
  dontDistribute = compose.dontDistribute;

  appendConfigureFlag = drv: x: compose.appendConfigureFlag x drv;
  appendConfigureFlags = drv: xs: compose.appendConfigureFlags xs drv;

  appendBuildFlag = drv: x: compose.appendBuildFlag x drv;
  appendBuildFlags = drv: xs: compose.appendBuildFlags xs drv;

  removeConfigureFlag = drv: x: compose.removeConfigureFlag x drv;

  addBuildTool = drv: x: compose.addBuildTool x drv;
  addBuildTools = drv: xs: compose.addBuildTools xs drv;

  addExtraLibrary = drv: x: compose.addExtraLibrary x drv;
  addExtraLibraries = drv: xs: compose.addExtraLibraries xs drv;

  addBuildDepend = drv: x: compose.addBuildDepend x drv;
  addBuildDepends = drv: xs: compose.addBuildDepends xs drv;

  addTestToolDepend = drv: x: compose.addTestToolDepend x drv;
  addTestToolDepends = drv: xs: compose.addTestToolDepends xs drv;

  addPkgconfigDepend = drv: x: compose.addPkgconfigDepend x drv;
  addPkgconfigDepends = drv: xs: compose.addPkgconfigDepends xs drv;

  addSetupDepend = drv: x: compose.addSetupDepend x drv;
  addSetupDepends = drv: xs: compose.addSetupDepends xs drv;

  enableCabalFlag = drv: x: compose.enableCabalFlag x drv;
  disableCabalFlag = drv: x: compose.disableCabalFlag x drv;

  markBroken = compose.markBroken;
  unmarkBroken = compose.unmarkBroken;
  markBrokenVersion = compose.markBrokenVersion;
  markUnbroken = compose.markUnbroken;

  disableParallelBuilding = compose.disableParallelBuilding;

  enableLibraryProfiling = compose.enableLibraryProfiling;
  disableLibraryProfiling = compose.disableLibraryProfiling;

  enableExecutableProfiling = compose.enableExecutableProfiling;
  disableExecutableProfiling = compose.disableExecutableProfiling;

  enableSharedExecutables = compose.enableSharedExecutables;
  disableSharedExecutables = compose.disableSharedExecutables;

  enableSharedLibraries = compose.enableSharedLibraries;
  disableSharedLibraries = compose.disableSharedLibraries;

  enableDeadCodeElimination = compose.enableDeadCodeElimination;
  disableDeadCodeElimination = compose.disableDeadCodeElimination;

  enableStaticLibraries = compose.enableStaticLibraries;
  disableStaticLibraries = compose.disableStaticLibraries;

  enableSeparateBinOutput = compose.enableSeparateBinOutput;

  appendPatch = drv: x: compose.appendPatch x drv;
  appendPatches = drv: xs: compose.appendPatches xs drv;

  setBuildTargets = drv: xs: compose.setBuildTargets xs drv;
  setBuildTarget = drv: x: compose.setBuildTarget x drv;

  doHyperlinkSource = compose.doHyperlinkSource;
  dontHyperlinkSource = compose.dontHyperlinkSource;

  disableHardening = drv: flags: compose.disableHardening flags drv;

  doStrip = compose.doStrip;
  dontStrip = compose.dontStrip;

  enableDWARFDebugging = compose.enableDWARFDebugging;

  sdistTarball = compose.sdistTarball;
  documentationTarball = compose.documentationTarball;

  linkWithGold = compose.linkWithGold;
  justStaticExecutables = compose.justStaticExecutables;

  buildFromSdist = compose.buildFromSdist;
  buildStrictly = compose.buildStrictly;

  disableOptimization = compose.disableOptimization;
  failOnAllWarnings = compose.failOnAllWarnings;

  checkUnusedPackages = compose.checkUnusedPackages;

  triggerRebuild = drv: i: compose.triggerRebuild i drv;

  overrideSrc = drv: src: compose.overrideSrc src drv;

  getBuildInputs = compose.getBuildInputs;
  getHaskellBuildInputs = compose.getHaskellBuildInputs;

  shellAware = compose.shellAware;
  packagesFromDirectory = compose.packagesFromDirectory;

  generateOptparseApplicativeCompletions = compose.generateOptparseApplicativeCompletions;

  allowInconsistentDependencies = compose.allowInconsistentDependencies;
}
