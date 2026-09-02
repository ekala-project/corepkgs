{ zig, makeSetupHook }:

makeSetupHook {
  name = "zig-hook";
  propagatedBuildInputs = [ zig ];
} ./setup-hook.sh
