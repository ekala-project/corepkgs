{
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  lib,
  coreutils,
}:

stdenvNoCC.mkDerivation rec {
  name = "lndir";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "jonringer";
    repo = "lndir-simple";
    rev = "v${version}";
    hash = "sha256-G+k7MExzG/lfUL6dpGFl4xWU3rOCZHbt4vU+/TMLZLs=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  dontBuild = true;
  installPhase = ''
    install -D lndir.sh $out/bin/lndir
    wrapProgram $out/bin/lndir \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}
  '';

  meta = {
    description = "Xorg's lndir utility, but in simple script form";
    licenses = [ lib.licenses.gpl3Plus ];
    mainProgram = "lndir";
  };
}
