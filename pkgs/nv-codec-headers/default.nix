{
  lib,
  stdenvNoCC,
  fetchgit,
  majorVersion ? "12",
}:

let
  sources = {
    "11" = {
      version = "11.1.5.2";
      hash = "sha256-KzaqwpzISHB7tSTruynEOJmSlJnAFK2h7/cRI/zkNPk=";
    };
    "12" = {
      version = "12.1.14.0";
      hash = "sha256-WJYuFmMGSW+B32LwE7oXv/IeTln6TNEeXSkquHh85Go=";
    };
  };
  pick = sources.${majorVersion};
in
stdenvNoCC.mkDerivation {
  pname = "nv-codec-headers";
  inherit (pick) version;

  src = fetchgit {
    url = "https://git.videolan.org/git/ffmpeg/nv-codec-headers.git";
    rev = "n${pick.version}";
    inherit (pick) hash;
  };

  makeFlags = [
    "PREFIX=$(out)"
  ];

  meta = {
    description = "FFmpeg version of headers for NVENC - major version ${majorVersion}";
    homepage = "https://ffmpeg.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
