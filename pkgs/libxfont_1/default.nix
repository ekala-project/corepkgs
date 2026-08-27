{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  libfontenc,
  xorgproto,
  freetype,
  xtrans,
  zlib,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxfont_1";
  version = "1.5.4";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxfont";
    tag = "libXfont-${finalAttrs.version}";
    hash = "sha256-qBJHQjm6OsKxq1oHEp0olJrfiFyld5FJzPq5pTDK/54=";
  };

  strictDeps = true;

  # No configure script in the git tree.
  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libfontenc
    xorgproto
    freetype
    xtrans
    zlib
  ];

  propagatedBuildInputs = [ xorgproto ];

  # prevents "misaligned_stack_error_entering_dyld_stub_binder"
  configureFlags = lib.optional stdenv.hostPlatform.isDarwin "CFLAGS=-O0";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X font handling library for server & utilities";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxfont";
    license = with lib.licenses; [
      mit
      mitOpenGroup
      hpnd
      hpndSellVariant
      # this was originally BSD-3-Clause-UC, however the University of California rescinded
      # clause 3, the advertising clause, in 1999 effectively reverting it to a BSD-3-Clause
      bsd3
    ];
    pkgConfigModules = [ "xfont" ];
    platforms = lib.platforms.unix;
  };
})
