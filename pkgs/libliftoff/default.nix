{
  lib,
  stdenv,
  fetchFromGitLab,
  meson,
  ninja,
  pkg-config,
  libdrm,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libliftoff";
  version = "0.5.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "emersion";
    repo = "libliftoff";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PcQY8OXPqfn8C30+GAYh0Z916ba5pik8U0fVpZtFb5g=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  buildInputs = [ libdrm ];

  meta = {
    description = "Lightweight KMS plane library";
    homepage = "https://gitlab.freedesktop.org/emersion/libliftoff";
    changelog = "https://gitlab.freedesktop.org/emersion/libliftoff/-/tags/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
