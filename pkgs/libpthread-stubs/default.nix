{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libpthread-stubs";
  version = "0.5";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "pthread-stubs";
    tag = "libpthread-stubs-${finalAttrs.version}";
    hash = "sha256-VvqHHqZn3bx+Ok95QXhSQFvswQfygMPx5WomuuWJTzQ=";
  };

  nativeBuildInputs = [
    autoreconfHook
    util-macros
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Provides a pkg-config file `pthread-stubs.pc` containing the Cflags/Libs flags applicable to programs/libraries that use only lightweight pthread API";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/pthread-stubs";
    # gitlab says x11-distribute-modifications but it's not
    # maybe due to https://github.com/spdx/spdx-online-tools/issues/540
    license = lib.licenses.x11;
    pkgConfigModules = [ "pthread-stubs" ];
    platforms = lib.platforms.unix;
  };
})
