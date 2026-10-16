{
  version,
  src-hash,
  ...
}:

{
  lib,
  stdenvNoCC,
  fetchgit,
}:

stdenvNoCC.mkDerivation {
  pname = "nv-codec-headers";
  inherit version;

  src = fetchgit {
    url = "https://git.videolan.org/git/ffmpeg/nv-codec-headers.git";
    rev = "n${version}";
    hash = src-hash;
  };

  makeFlags = [
    "PREFIX=$(out)"
  ];

  meta = {
    description = "FFmpeg version of headers for NVENC";
    homepage = "https://ffmpeg.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
