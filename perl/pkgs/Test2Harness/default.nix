{
  buildPerlPackage,
  DataUUID,
  fetchurl,
  gotofile,
  Importer,
  LongJump,
  ScopeGuard,
  stdenv,
  TermTable,
  Test2PluginMemUsage,
  Test2PluginUUID,
  Test2Suite,
  YAMLTiny,
}:

buildPerlPackage rec {
  pname = "Test2-Harness";
  version = "1.000161";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Harness-${version}.tar.gz";
    hash = "sha256-SXO3mx7tUwVxXuc9itySNtp5XH1AkNg7FQ6hMc1ltBQ=";
  };

  checkPhase = ''
    patchShebangs ./t ./scripts/yath
    export AUTOMATED_TESTING=1
    ./scripts/yath test -j $NIX_BUILD_CORES
  '';

  # The t/integration/preload.t test is broken on riscv64
  # https://github.com/Test-More/Test2-Harness/issues/290
  doCheck = !stdenv.hostPlatform.isRiscV;

  propagatedBuildInputs = [
    DataUUID
    Importer
    LongJump
    ScopeGuard
    TermTable
    Test2PluginMemUsage
    Test2PluginUUID
    Test2Suite
    YAMLTiny
    gotofile
  ];
  meta = {
    changelog = "https://github.com/Test-More/Test2-Harness/blob/v${version}/Changes";
    description = "New and improved test harness with better Test2 integration";
    mainProgram = "yath";
    broken = stdenv.hostPlatform.isDarwin; # never built on Hydra https://hydra.nixos.org/job/nixpkgs/staging-next/perl534Packages.Test2Harness.x86_64-darwin
  };
}
