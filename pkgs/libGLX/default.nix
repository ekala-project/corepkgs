{
  stdenv,
  mesa ? null,
  libglvnd ? null,
}:
# `libglvnd` does not work (yet?) on macOS.
if stdenv.hostPlatform.isDarwin then mesa else libglvnd
