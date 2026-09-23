{
  stdenv,
  libglvnd ? null,
}:
# Android NDK provides an OpenGL implementation, we can just use that.
#
# On macOS, the SDK provides the OpenGL framework in `stdenv`.
# Packages that still need GLX specifically can pull in `libGLX`
# instead. If you have a package that should work without X11 but it
# can't find the library, it may help to add the path to
# `$NIX_CFLAGS_COMPILE`:
#
#    preConfigure = ''
#      export NIX_CFLAGS_COMPILE+=" -L$SDKROOT/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries"
#    '';
#
if stdenv.hostPlatform.useAndroidPrebuilt then
  stdenv
else if stdenv.hostPlatform.isDarwin then
  null
else
  libglvnd
