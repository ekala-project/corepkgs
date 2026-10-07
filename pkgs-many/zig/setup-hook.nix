{
  lib,
  zig,
  makeSetupHook,
}:

makeSetupHook {
  name = "zig-hook";
  propagatedBuildInputs = [ zig ];
  substitutions = {
    zigDefaultCpuFlag = "-Dcpu=baseline";
    zigDefaultOptimizeFlag =
      if lib.versionAtLeast zig.version "0.12" then "--release=safe" else "-Doptimize=ReleaseSafe";
  };
} ./setup-hook.sh
