{
  lib,
  stdenv,
  fetchFromGitHub,
  docbook-xsl,
  libxslt,
  meson,
  ninja,
  pkg-config,
  bash-completion,
  libcap,
  libselinux,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bubblewrap";
  version = "0.13.1";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "bubblewrap";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sgIATYiBYbHaftA+ShIqfxS3OScz7VurjPciL2WB1oQ=";
  };

  outputs = [
    "out"
    "dev"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error=format-overflow";

  postPatch = ''
    substituteInPlace tests/libtest.sh \
      --replace "/var/tmp" "$TMPDIR"
  '';

  nativeBuildInputs = [
    docbook-xsl
    libxslt
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  buildInputs = [
    bash-completion
    libcap
    libselinux
  ];

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "bwrap --version";
    };
    # build = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
    # Tests disabled: incompatible with Nix sandbox
  };

  meta = {
    changelog = "https://github.com/containers/bubblewrap/releases/tag/${finalAttrs.src.rev}";
    description = "Unprivileged sandboxing tool";
    homepage = "https://github.com/containers/bubblewrap";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux;
    mainProgram = "bwrap";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "projectatomic" finalAttrs.version;
  };
})
