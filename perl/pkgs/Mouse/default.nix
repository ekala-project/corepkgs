{
  buildPerlModule,
  fetchurl,
  lib,
  ModuleBuildXSUtil,
  stdenv,
  TestException,
  TestFatal,
  TestLeakTrace,
  TestOutput,
  TestRequires,
  TryTiny,
}:

buildPerlModule {
  pname = "Mouse";
  version = "2.5.10";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SK/SKAJI/Mouse-v2.5.10.tar.gz";
    hash = "sha256-zo3COUYVOkZ/8JdlFn7iWQ9cUCEg9IotlEFzPzmqMu4=";
  };
  buildInputs = [
    ModuleBuildXSUtil
    TestException
    TestFatal
    TestLeakTrace
    TestOutput
    TestRequires
    TryTiny
  ];
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isi686 "-fno-stack-protector";
  hardeningDisable = lib.optional stdenv.hostPlatform.isi686 "stackprotector";
  meta = {
    description = "Moose minus the antlers";
  };
}
