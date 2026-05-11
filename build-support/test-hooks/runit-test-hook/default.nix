{
  lib,
  stdenv,
  makeSetupHook,
  runit,
  netcat,
}:

makeSetupHook {
  name = "runit-test-hook";

  propagatedBuildInputs = [
    runit
    netcat
  ];

  substitutions = {
    runitPackage = runit;
    netcatPackage = netcat;
  };

  meta = {
    description = "Setup hook for running runit-supervised services during tests";
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.unix;
  };
} ./runit-test-hook.sh
