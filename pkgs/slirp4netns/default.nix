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
  version = "1.3.6";

  src = fetchFromGitHub {
    owner = "rootless-containers";
    repo = "slirp4netns";
    tag = "v${finalAttrs.version}";
    sha256 = "sha256-vjOIIIlOmidAgkZEiwO9rXAKQUOMFNe8NROBOF5nJQ8=";
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
    platforms = lib.platforms.linux;
    mainProgram = "slirp4netns";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "slirp4netns_project" finalAttrs.version;
  };
})
