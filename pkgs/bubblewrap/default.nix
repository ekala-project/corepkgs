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
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bubblewrap";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "bubblewrap";
    rev = "v${finalAttrs.version}";
    hash = "sha256-8IDMLQPeO576N1lizVudXUmTV6hNOiowjzRpEWBsZ+U=";
  };

  outputs = [
    "out"
    "dev"
  ];

  mesonBuildType = "release";

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

  # incompatible with Nix sandbox
  doCheck = false;

  meta = {
    changelog = "https://github.com/containers/bubblewrap/releases/tag/${finalAttrs.src.rev}";
    description = "Unprivileged sandboxing tool";
    homepage = "https://github.com/containers/bubblewrap";
    license = lib.licenses.lgpl2Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "bwrap";
  };
})
