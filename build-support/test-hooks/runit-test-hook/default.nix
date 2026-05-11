{
  lib,
  stdenv,
  makeSetupHook,
  runit,
  netcat-gnu,
}:

makeSetupHook {
  name = "runit-test-hook";

  propagatedBuildInputs = [
    runit
    netcat-gnu
  ];

  substitutions = {
    runitPackage = runit;
    netcatPackage = netcat-gnu;
  };

  meta = {
    description = "Setup hook for running runit-supervised services during tests";
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.unix;
  };
} ./runit-test-hook.sh
