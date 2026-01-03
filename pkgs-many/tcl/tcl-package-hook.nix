{ makeSetupHook, buildPackages }:

makeSetupHook {
  name = "tcl-package-hook";
  propagatedBuildInputs = [ buildPackages.makeBinaryWrapper ];
  meta = {
    inherit (meta) maintainers platforms;
  };
} ./tcl-package-hook.sh
