{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  glib,
  libcap,
  libseccomp,
  libslirp,
  slirp4netns,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "slirp4netns";
  version = "1.3.4";

  src = fetchFromGitHub {
    owner = "rootless-containers";
    repo = "slirp4netns";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-/ZnlWv5kSkYMiO2mTs6mY70QGBm0FsIDyd+gGaVK9rs=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    glib
    libcap
    libseccomp
    libslirp
  ];

  enableParallelBuilding = true;
  strictDeps = true;

  outputs = [
    "out"
    "man"
  ];

  passthru.tests = {
    version = testers.testVersion {
      package = slirp4netns;
      command = "slirp4netns --version";
    };
  };

  meta = {
    homepage = "https://github.com/rootless-containers/slirp4netns";
    description = "User-mode networking for unprivileged network namespaces";
    license = lib.licenses.gpl2Only;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "slirp4netns";
  };
})
