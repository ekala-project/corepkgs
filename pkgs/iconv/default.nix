{
  lib,
  stdenv,
  libc,
  libiconv,
  freebsd ? null,
}:
if
  lib.elem stdenv.hostPlatform.libc [
    "glibc"
    "musl"
  ]
then
  lib.getBin libc
else if stdenv.hostPlatform.isDarwin then
  lib.getBin libiconv
else if stdenv.hostPlatform.isFreeBSD then
  lib.getBin freebsd.iconv
else
  lib.getBin libiconv
