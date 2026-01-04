{ makeSetupHook, buildPackages }:

makeSetupHook {
  name = "tcl-package-hook";
  propagatedBuildInputs = [ buildPackages.makeBinaryWrapper ];
} ./tcl-package-hook.sh
