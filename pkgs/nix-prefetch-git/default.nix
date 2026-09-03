{
  lib,
  stdenv,
  makeWrapper,
  bash,
  coreutils,
  sed,
  findutils,
  gawk,
  git,
  git-lfs,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "nix-prefetch-git";
  version = "1.0.0";

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  dontUnpack = true;

  installPhase = ''
    install -vD ${./nix-prefetch-git.sh} $out/bin/$pname;
    wrapProgram $out/bin/$pname --prefix PATH : ${
      lib.makeBinPath [
        findutils
        gawk
        git
        git-lfs
        coreutils
        sed
      ]
    } --set HOME /homeless-shelter
  '';

  preferLocalBuild = true;

  meta = {
    description = "Script used to obtain source hashes for fetchgit";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
    mainProgram = "nix-prefetch-git";
  };
})
