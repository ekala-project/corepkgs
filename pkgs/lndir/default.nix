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
    rev = "6dab4d5081840ac1774728958d863cc2ebd07a3d";
    hash = "sha256-a4UUm3J2lPy5r2eaNpUXN6fNfy3zJ7D0CACyqUB2iGY=";
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
